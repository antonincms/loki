(import 'dashboard-utils.libsonnet') {
  grafanaDashboards+:: if $._config.ssd.enabled then {} else {
    local dashboards = self,

    'loki-reads-resources.json': {
      index_gateway_pod_matcher:: if $._config.meta_monitoring.enabled
      then 'container=~"loki|index-gateway", pod=~"(index-gateway.*|loki-single-binary)"'
      else 'container="index-gateway"',
      index_gateway_job_matcher:: if $._config.meta_monitoring.enabled
      then '(index-gateway.*|loki-single-binary)'
      else 'index-gateway',

      ingester_pod_matcher:: if $._config.meta_monitoring.enabled
      then 'container=~"loki|ingester|partition-ingester", pod=~"(ingester.*|partition-ingester.*|loki-single-binary)"'
      else 'container=~"ingester|partition-ingester"',
      ingester_job_matcher:: if $._config.meta_monitoring.enabled
      then '(ingester.*|partition-ingester.*|loki-single-binary)'
      else '(ingester|partition-ingester).*',
    } + ($.dashboard('Loki / Reads Resources', uid='reads-resources'))
        .addCluster()
        .addNamespace()
        .addTag()
        .addRowIf(
      $._config.internal_components,
      $.row('Gateway')
      .addPanel(
        $.containerCPUUsagePanel('CPU', 'cortex-gw(-internal)?'),
      )
      .addPanel(
        $.containerMemoryWorkingSetPanel('Memory (workingset)', 'cortex-gw(-internal)?'),
      )
      .addPanel(
        $.goHeapInUsePanel('Memory (go heap inuse)', 'cortex-gw(-internal)?'),
      )
    )
        .addRow(
      $.row('Query Frontend')
      .addPanel(
        $.containerCPUUsagePanel('CPU', 'query-frontend'),
      )
      .addPanel(
        $.containerMemoryWorkingSetPanel('Memory (workingset)', 'query-frontend'),
      )
      .addPanel(
        $.goHeapInUsePanel('Memory (go heap inuse)', 'query-frontend'),
      )
    )
        .addRow(
      $.row('Query Scheduler')
      .addPanel(
        $.containerCPUUsagePanel('CPU', 'query-scheduler'),
      )
      .addPanel(
        $.containerMemoryWorkingSetPanel('Memory (workingset)', 'query-scheduler'),
      )
      .addPanel(
        $.goHeapInUsePanel('Memory (go heap inuse)', 'query-scheduler'),
      )
    )
        .addRow(
      $.row('Querier')
      .addPanel(
        $.containerCPUUsagePanel('CPU', 'querier'),
      )
      .addPanel(
        $.containerMemoryWorkingSetPanel('Memory (workingset)', 'querier'),
      )
      .addPanel(
        $.goHeapInUsePanel('Memory (go heap inuse)', 'querier'),
      )
      .addPanel(
        $.newQueryPanel('Disk Writes', 'Bps') +
        $.queryPanel(
          'sum by(%s, device) (rate(node_disk_written_bytes_total[$__rate_interval])) + %s' % [$._config.per_node_label, $.filterNodeDiskContainer('querier')],
          '{{%s}} - {{device}}' % $._config.per_instance_label
        ) +
        $.withStacking,
      )
      .addPanel(
        $.newQueryPanel('Disk Reads', 'Bps') +
        $.queryPanel(
          'sum by(%s,device) (rate(node_disk_read_bytes_total[$__rate_interval])) + %s' % [$._config.per_node_label, $.filterNodeDiskContainer('querier')],
          '{{%s}} - {{device}}' % $._config.per_instance_label
        ) +
        $.withStacking,
      )
      .addPanel(
        $.containerDiskSpaceUtilizationPanel('Disk Space Utilization', 'querier'),
      )
    )
        // Otherwise we add the index gateway information
        .addRow(
      $.row('Index Gateway')
      .addPanel(
        $.CPUUsagePanel('CPU', dashboards['loki-reads-resources.json'].index_gateway_pod_matcher),
      )
      .addPanel(
        $.memoryWorkingSetPanel('Memory (workingset)', dashboards['loki-reads-resources.json'].index_gateway_pod_matcher),
      )
      .addPanel(
        $.goHeapInUsePanel('Memory (go heap inuse)', dashboards['loki-reads-resources.json'].index_gateway_job_matcher),
      )
      .addPanel(
        $.newQueryPanel('Disk Writes', 'Bps') +
        $.queryPanel(
          'sum by(%s, device) (rate(node_disk_written_bytes_total[$__rate_interval])) + %s' % [$._config.per_node_label, $.filterNodeDisk(dashboards['loki-reads-resources.json'].index_gateway_pod_matcher)],
          '{{%s}} - {{device}}' % $._config.per_instance_label
        ) +
        $.withStacking,
      )
      .addPanel(
        $.newQueryPanel('Disk Reads', 'Bps') +
        $.queryPanel(
          'sum by(%s, device) (rate(node_disk_read_bytes_total[$__rate_interval])) + %s' % [$._config.per_node_label, $.filterNodeDisk(dashboards['loki-reads-resources.json'].index_gateway_pod_matcher)],
          '{{%s}} - {{device}}' % $._config.per_instance_label
        ) +
        $.withStacking,
      )
      .addPanel(
        $.containerDiskSpaceUtilizationPanel('Disk Space Utilization', dashboards['loki-reads-resources.json'].index_gateway_job_matcher),
      )
    )
        .addRow(
      $.row('Bloom Gateway')
      .addPanel(
        $.containerCPUUsagePanel('CPU', 'bloom-gateway'),
      )
      .addPanel(
        $.containerMemoryWorkingSetPanel('Memory (workingset)', 'bloom-gateway'),
      )
      .addPanel(
        $.goHeapInUsePanel('Memory (go heap inuse)', 'bloom-gateway'),
      )
      .addPanel(
        $.newQueryPanel('Disk Writes', 'Bps') +
        $.queryPanel(
          'sum by(%s, device) (rate(node_disk_written_bytes_total[$__rate_interval])) + %s' % [$._config.per_node_label, $.filterNodeDiskContainer('bloom-gateway')],
          '{{%s}} - {{device}}' % $._config.per_instance_label
        ) +
        $.withStacking,
      )
      .addPanel(
        $.newQueryPanel('Disk Reads', 'Bps') +
        $.queryPanel(
          'sum by(%s, device) (rate(node_disk_read_bytes_total[$__rate_interval])) + %s' % [$._config.per_node_label, $.filterNodeDiskContainer('bloom-gateway')],
          '{{%s}} - {{device}}' % $._config.per_instance_label
        ) +
        $.withStacking,
      )
      .addPanel(
        $.containerDiskSpaceUtilizationPanel('Disk Space Utilization', 'bloom-gateway'),
      )
    )
        .addRow(
      $.row('Ingester')
      .addPanel(
        $.CPUUsagePanel('CPU', dashboards['loki-reads-resources.json'].ingester_pod_matcher),
      )
      .addPanel(
        $.memoryWorkingSetPanel('Memory (workingset)', dashboards['loki-reads-resources.json'].ingester_pod_matcher),
      )
      .addPanel(
        $.goHeapInUsePanel('Memory (go heap inuse)', dashboards['loki-reads-resources.json'].ingester_job_matcher),
      )
    )
        .addRow(
      $.row('Ruler')
      .addPanel(
        $.newQueryPanel('Rules') +
        $.queryPanel(
          'sum by(%(label)s) (loki_prometheus_rule_group_rules{%(matcher)s}) or sum by(%(label)s) (cortex_prometheus_rule_group_rules{%(matcher)s})' % { label: $._config.per_instance_label, matcher: $.jobMatcher('ruler') },
          '{{%s}}' % $._config.per_instance_label
        ),
      )
      .addPanel(
        $.containerCPUUsagePanel('CPU', 'ruler'),
      )
      .addPanel(
        $.containerMemoryWorkingSetPanel('Memory (workingset)', 'ruler'),
      )
      .addPanel(
        $.goHeapInUsePanel('Memory (go heap inuse)', 'ruler'),
      )
    ),
  },
}
