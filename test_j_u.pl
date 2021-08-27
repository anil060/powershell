
use Getopt::Std;
use XML::Simple;
require Text::CSV;

# it seems that service accounts have:
# 1) a name without ','
# 2) am email that starts with '_'     # not all, see svc-qascript
# 3) an email address without '@'      # not all, see svc-qascript

sub usage
{
   print "Usage:  $0  [-q][-v]  <filename>\n";
   print "        -q  don't count accounts, users\n";
   print "        -v  print LDAP accounts which are not in JazzUsers\n";
   exit 1;
}

getopts( 'qv' );
$quiet   = $opt_q;
$verbose = $opt_v;

# we need a filename
if ( $#ARGV != 0 )
{
   usage();
}

# read file into array
$filename = shift;
if ( $filename =~ /xml/i )
{
   $xml = XMLin( $filename, KeyAttr => "" );    
   $contributor = %$xml{ "contributor" };
   for $x (  @$contributor )
   {
      $name = %$x{"name"};
      $email = %$x{"emailAddress"};
      $userID = %$x{"userId"};
      push( @accounts, "$name:$email:$userID" );
   }
}
elsif ( $filename =~ /csv/i )
{
   $csv = Text::CSV->new ({ binary => 1, eol => $/ });
   open $csvHandle, "<", $filename or die "$filename: $!";
   while ( $row = $csv->getline( $csvHandle ) ) 
   {
       ( $version, $name, $userID, $email ) = @$row;
       next if ( $version =~ /Version/ );
       push( @accounts, "$name:$email:$userID" );
   }
   close $csvHandle;
}
else
{
   print "Sorry, this script expects a filename that ends in \".csv\" or \".xml\".\n";
   exit 1;
}

@accounts = sort @accounts;
for $account ( @accounts )
{
   ++$accountCount;
   print "accounts: $accountCount\r" unless ( $quiet );

   ( $name, $email, $userID ) = split( /:/, $account );
#   print "$name  $email  $userID\n";
#   next;

   # collect max field lengths for later 
   $lengthName = length( $name );
   $maxName = $lengthName if ( $maxName < $lengthName );
   $lengthEmail = length( $email );
   $maxEmail = $lengthEmail if ( $maxEmail < $lengthEmail );
   $lengthUserID = length( $userID );
   $maxUserID = $lengthUserID if ( $maxUserID < $lengthUserID );

   # separate into service accounts and user accounts
   if ( $email !~ /@/ )    # service accounts, doesn't catch every one
   {
      push( @service, "$name:$email:$userID" );
   }
   else                    
   {
      push( @user, "$name:$email:$userID" );
   }
}
print "\n" unless ( $quiet );

# separate into in LDAP, and not in LDAP
for $user ( @user )
{
   ++$userCount;
   print "users: $userCount\r" unless ( $quiet );
#   last if ( $userCount == 200 );

   ( $name, $email, $userID ) = split( /:/, $user );
   chomp( $ldap = `dsquery * -filter "(mail=$email)" -attr memberof` );

   if ( length( $ldap ) == 0 )
   {
      push( @notInLDAP, $user );
   }
   else
   {
      if ( $ldap =~ /cn=jazzusers/i )
      {
         push( @jazzusers, "$user" );
      }
      else
      {
         push( @inLDAP, "$user" );
      }
   }
}
print "\n" unless ( $quiet ); 

print "\n";
print "not in LDAP\n";
print "-----------\n";
for $user ( @notInLDAP )
{
   ( $name, $email, $userID ) = split( /:/, $user );
   printf "%-*s  %-*s  %-*s\n", $maxName, $name, $maxEmail, $email, $maxUserID, $userID;

}

print "\n";
print "not in JazzUsers\n";
print "----------------\n";
for $user ( @inLDAP )
{
   ( $name, $email, $userID, $ldap ) = split( /:/, $user );
   printf "%-*s  %-*s  %-*s  %s\n", $maxName, $name, $maxEmail, $email, $maxUserID, $userID, $ldap;

}
exit unless ( $verbose );

print "\n";
print "in JazzUsers\n";
print "------------\n";
for $user ( @jazzusers )
{
   ( $name, $email, $userID, $ldap ) = split( /:/, $user );
   printf "%-*s  %-*s  %-*s  %s\n", $maxName, $name, $maxEmail, $email, $maxUserID, $userID, $ldap;

}
