package distributor

import (
	"context"
	"time"

	"github.com/go-kit/log"
	"github.com/grafana/dskit/ring"
	ring_client "github.com/grafana/dskit/ring/client"
	"github.com/grafana/dskit/services"
	"github.com/grafana/loki/v3/pkg/distributor/clientpool"
	ingester_client "github.com/grafana/loki/v3/pkg/ingester/client"
	"github.com/grafana/loki/v3/pkg/util"
	"github.com/pkg/errors"
	"github.com/prometheus/client_golang/prometheus"
)

type RateStoreStandalone struct {
	services.Service
	rateStore *rateStore

	subservices        *services.Manager
	subservicesWatcher *services.FailureWatcher
}

func NewRateStoreStandalone(
	cfg RateStoreConfig,
	clientCfg ingester_client.Config,
	r ring.ReadRing,
	l Limits,
	metricsNamespace string,
	registerer prometheus.Registerer,
	logger log.Logger,
) (*RateStoreStandalone, error) {
	s := &RateStoreStandalone{}

	internalIngesterClientFactory := func(addr string) (ring_client.PoolClient, error) {
		internalCfg := clientCfg
		internalCfg.Internal = true
		return ingester_client.New(internalCfg, addr)
	}

	cf := clientpool.NewPool(
		"rate-store-standalone",
		clientCfg.PoolConfig,
		r,
		ring_client.PoolAddrFunc(internalIngesterClientFactory),
		logger,
		metricsNamespace,
	)

	s.rateStore = &rateStore{
		ring:            r,
		clientPool:      cf,
		maxParallelism:  cfg.MaxParallelism,
		ingesterTimeout: cfg.IngesterReqTimeout,
		rateKeepAlive:   1 * time.Hour,
		limits:          l,
		metrics:         newRateStoreMetrics(registerer, true),
		rates:           make(map[string]map[uint64]expiringRate),
	}

	rateCollectionInterval := util.DurationWithJitter(cfg.StreamRateUpdateInterval, 0.2)
	rs := services.
		NewTimerService(rateCollectionInterval, s.rateStore.instrumentedUpdateAllRates, s.rateStore.instrumentedUpdateAllRates, nil).
		WithName("rate store standalone")

	var err error
	s.subservices, err = services.NewManager(rs)
	if err != nil {
		return nil, errors.Wrap(err, "services manager")
	}
	s.subservicesWatcher = services.NewFailureWatcher()
	s.subservicesWatcher.WatchManager(s.subservices)
	s.Service = services.NewBasicService(s.starting, s.running, s.stopping)

	return s, nil
}

func (s *RateStoreStandalone) starting(ctx context.Context) error {
	return services.StartManagerAndAwaitHealthy(ctx, s.subservices)
}

func (s *RateStoreStandalone) running(ctx context.Context) error {
	<-ctx.Done()
	return nil
}

func (s *RateStoreStandalone) stopping(_ error) error {
	return services.StopManagerAndAwaitStopped(context.Background(), s.subservices)
}
