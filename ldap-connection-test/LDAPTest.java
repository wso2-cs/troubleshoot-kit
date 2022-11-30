import javax.naming.Context;
import javax.naming.NamingEnumeration;
import javax.naming.NamingException;
import javax.naming.directory.Attributes;
import javax.naming.directory.DirContext;
import javax.naming.directory.InitialDirContext;
import javax.naming.directory.SearchControls;
import javax.naming.directory.SearchResult;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Hashtable;

/**
 * https://github.com/rksk/ldap-test
 */

public class LDAPTest {

    private static String LDAP_URL = "ldap://localhost:10389";
    private static String LDAP_USER = "uid=admin,ou=system";
    private static String LDAP_PASSWORD = "admin";
    private static String LDAP_SEARCH_BASE = "ou=Users,dc=wso2,dc=org";
    private static String SEARCH_FILTER = "(&(objectClass=person)(uid=admin))";
    private static String ATTRIBUTE_TO_PRINT = "uid";
    private static String LDAP_REFERRAL = "follow"; //follow or ignore
    private static String KEYSTORE = "";
    private static String KEYSTORE_PASSWORD = "wso2carbon";
    private static int NUMBER_OF_ITERATIONS = 10;
    private static long DELAY_BETWEEN_ITERATIONS = 2000; //ms

    public static void main(String[] args){

        if(args != null  && args.length == 1) {
            LDAP_PASSWORD = args[0];
        }else if(args != null  && args.length == 2) {
            LDAP_PASSWORD = args[0];
            KEYSTORE = args[1];
        }else if(args != null  && args.length == 3) {
            LDAP_PASSWORD = args[0];
            KEYSTORE = args[1];
            KEYSTORE_PASSWORD = args[2];
        }

        System.out.println("LDAP URL: " + LDAP_URL);
        System.out.println("LDAP User: " + LDAP_USER);
        System.out.println("LDAP Search Base: " + LDAP_SEARCH_BASE);
        System.out.println("LDAP Search Filter: " + SEARCH_FILTER);
        System.out.println("LDAP Referral: " + LDAP_REFERRAL);
        System.out.println("LDAP Attribute: " + ATTRIBUTE_TO_PRINT);
        System.out.println("Trust store location: " + KEYSTORE);

        System.setProperty("javax.net.ssl.trustStore", KEYSTORE);
        System.setProperty("javax.net.ssl.trustStorePassword", KEYSTORE_PASSWORD);

        System.out.println("\n============  Test is started  ================");

        Hashtable<String, String > environment = new Hashtable<String, String >();
        environment.put(Context.INITIAL_CONTEXT_FACTORY, "com.sun.jndi.ldap.LdapCtxFactory");
        environment.put(Context.SECURITY_AUTHENTICATION, "simple");
        environment.put(Context.REFERRAL, LDAP_REFERRAL);
        environment.put(Context.PROVIDER_URL, LDAP_URL);
        environment.put(Context.SECURITY_PRINCIPAL, LDAP_USER);
        environment.put(Context.SECURITY_CREDENTIALS, LDAP_PASSWORD);

        DirContext ctx = null;
        NamingEnumeration<SearchResult> results = null;
        SearchResult searchResult = null;
        SimpleDateFormat sdf = new SimpleDateFormat("MMM dd,yyyy HH:mm:ss.SSSZ");
        long t1,t2,t3,t4;

        for(int i=1; i<=NUMBER_OF_ITERATIONS; i++) {

            try {
                t1=0;t2=0;t3=0;t4=0;
                System.out.println("\n\n===== Itertation " + i + " =====");

                t1 = System.currentTimeMillis();
                System.out.println(sdf.format(new Date(System.currentTimeMillis())));
                System.out.println("==  Dir context started ==");

                ctx = new InitialDirContext(environment);

                t2 = System.currentTimeMillis();
                System.out.println("==  Dir context is finished:  " + (t2 - t1) + "ms ==");

                SearchControls searchControls = new SearchControls();
                searchControls.setSearchScope(SearchControls.SUBTREE_SCOPE);

                results = ctx.search(LDAP_SEARCH_BASE, SEARCH_FILTER, searchControls);

                t3 = System.currentTimeMillis();
                System.out.println("== LDAP Search done: " + (t3 - t2) + "ms ==");

                int index = 1;
                
                try {
                    while (results.hasMore()) {
                        try {
                            searchResult = results.next();
                            Attributes attrs = searchResult.getAttributes();
                            System.out.println(index++ + ". " + attrs.get(ATTRIBUTE_TO_PRINT));
                        } catch (Exception e) {
                            System.out.println("An error occurred");
                            e.printStackTrace();
                        }
                    }
                } catch (NamingException e) {
                    System.out.println("An error occurred while checking hasMore()");
                    e.printStackTrace();
                }                

                t4 = System.currentTimeMillis();
                System.out.println("== Results printing done: " + (t4 - t3) + "ms ==");

            } catch (NamingException e) {
                System.out.println("An error occurred");
                e.printStackTrace();
            } finally {
                if (results != null) {
                    try {
                        results.close();
                    } catch (NamingException e) {
                        e.printStackTrace();
                    }
                }
                if (ctx != null) {
                    try {
                        ctx.close();
                    } catch (NamingException e) {
                        e.printStackTrace();
                    }
                }
            }

            try {
                Thread.sleep(DELAY_BETWEEN_ITERATIONS);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }

        System.out.println("=====  Test is finished =====");
        System.exit(0);
    }

}
