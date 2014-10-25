package graphite;

import java.net.InetAddress;
import java.util.Arrays;
import java.util.HashSet;
import java.util.concurrent.TimeUnit;

import com.yammer.metrics.Metrics;
import com.yammer.metrics.core.Metric;
import com.yammer.metrics.core.MetricName;
import com.yammer.metrics.core.MetricPredicate;
import com.yammer.metrics.reporting.GraphiteReporter;

public class ReportAgent {
    // Constants variables for Graphite host, port and period.
    private static final String GRAPHITE_HOST = "my graphite host name";
    private static final int GRAPHITE_PORT = 2003;
    private static final long REFRESH_PERIOD = 10;
    // Check TimeUnit javadoc for other possible values here like TimeUnit.MINUTES, etc
    private static final TimeUnit REFRESH_PERIOD_UNIT = TimeUnit.SECONDS;

    // Cassandra metric predicates, to ignor system based tables.
    static MetricPredicate CASS_PREDICATE = new MetricPredicate() {
        private HashSet<String> ignore_cfs = new HashSet<String>(Arrays.asList(
            "system",
            "system_auth",
            "system_traces"
        ));
        
        @Override
        public boolean matches(MetricName name, Metric metric) {
            if (name.getType().equals("Connection") ||
                    (name.getType().equals("ColumnFamily") &&
                        ignore_cfs.contains(name.getScope().split("\\.")[0])) ||
                    (name.getType().equals("Streaming") && name.hasScope())) {
                return false;
            }
            return true;
        }
    };

    public static void premain(String agentArgs) throws Exception {
        String hostname = InetAddress.getLocalHost().getHostName();
        String prefix =  hostname.split("\\.")[0] + ".cassandra.";
        GraphiteReporter.enable(Metrics.defaultRegistry(), REFRESH_PERIOD, REFRESH_PERIOD_UNIT, GRAPHITE_HOST, GRAPHITE_PORT, prefix, CASS_PREDICATE);
    }
}
