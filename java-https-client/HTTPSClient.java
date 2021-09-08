import java.io.BufferedReader;
import java.io.FileInputStream;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.io.OutputStreamWriter;
import java.io.PrintWriter;
import java.security.KeyStore;

import javax.net.ssl.KeyManager;
import javax.net.ssl.KeyManagerFactory;
import javax.net.ssl.SSLContext;
import javax.net.ssl.SSLSession;
import javax.net.ssl.SSLSocket;
import javax.net.ssl.SSLSocketFactory;
import javax.net.ssl.TrustManager;
import javax.net.ssl.TrustManagerFactory;

public class HTTPSClient {

    private static final String KEYSTORE_PATH = "/Users/apple/testclient/wso2carbon.jks";
    private static final String KEYSTORE_PASSWORD = "wso2carbon";
    private static final String KEYSTORE_TYPE = "JKS";
    private static final String KEY_MANAGER_ALGORITHM = "SunX509";
    private static final String SSL_PROTOCOL = "TLSv1.2";

    private static final String host = "localhost";
    private static final int port = 8243;
    private static final String path = "/services/Version";

    public static void main(String[] args){
        HTTPSClient client = new HTTPSClient();
        client.run();
    }

    // Create the and initialize the SSLContext
    private SSLContext createSSLContext(){
        try{
            KeyStore keyStore = KeyStore.getInstance("JKS");
            keyStore.load(new FileInputStream(KEYSTORE_PATH),KEYSTORE_PASSWORD.toCharArray());

            // Create key manager
            KeyManagerFactory keyManagerFactory = KeyManagerFactory.getInstance(KEY_MANAGER_ALGORITHM);
            keyManagerFactory.init(keyStore, KEYSTORE_PASSWORD.toCharArray());
            KeyManager[] km = keyManagerFactory.getKeyManagers();

            // Create trust manager
            TrustManagerFactory trustManagerFactory = TrustManagerFactory.getInstance(KEY_MANAGER_ALGORITHM);
            trustManagerFactory.init(keyStore);
            TrustManager[] tm = trustManagerFactory.getTrustManagers();

            // Initialize SSLContext
            SSLContext sslContext = SSLContext.getInstance(SSL_PROTOCOL);
            sslContext.init(km,  tm, null);

            return sslContext;
        } catch (Exception ex){
            ex.printStackTrace();
        }

        return null;
    }

    // Start to run the server
    public void run(){
        SSLContext sslContext = this.createSSLContext();

        try{
            // Create socket factory
            SSLSocketFactory sslSocketFactory = sslContext.getSocketFactory();

            // Create socket
            SSLSocket sslSocket = (SSLSocket) sslSocketFactory.createSocket(this.host, this.port);

            System.out.println("SSL client started");
            new ClientThread(sslSocket).start();
        } catch (Exception ex){
            ex.printStackTrace();
        }
    }

    // Thread handling the socket to server
    static class ClientThread extends Thread {
        private SSLSocket sslSocket = null;

        ClientThread(SSLSocket sslSocket){
            this.sslSocket = sslSocket;
        }

        public void run(){
            sslSocket.setEnabledCipherSuites(sslSocket.getSupportedCipherSuites());

            try{
                // Start handshake
                sslSocket.startHandshake();

                // Get session after the connection is established
                SSLSession sslSession = sslSocket.getSession();

                System.out.println("SSLSession :");
                System.out.println("\tProtocol : "+sslSession.getProtocol());
                System.out.println("\tCipher suite : "+sslSession.getCipherSuite());

                // Start handling application content
                InputStream inputStream = sslSocket.getInputStream();
                OutputStream outputStream = sslSocket.getOutputStream();

                BufferedReader bufferedReader = new BufferedReader(new InputStreamReader(inputStream));
                PrintWriter printWriter = new PrintWriter(new OutputStreamWriter(outputStream));

                // Write data
                printWriter.print("GET " + path + " HTTP/1.0\r\n");
                printWriter.print("\r\n");
                printWriter.print("\r\n");
                printWriter.flush();
                String line = null;
                while((line = bufferedReader.readLine()) != null){
                    System.out.println("Inut : "+line);

                    if(line.trim().equals("HTTP/1.1 200\r\n")){
                        break;
                    }
                }

                sslSocket.close();
            } catch (Exception ex) {
                ex.printStackTrace();
            }
        }
    }
}