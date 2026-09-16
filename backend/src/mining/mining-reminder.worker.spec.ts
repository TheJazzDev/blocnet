import {
  MINING_REMINDER_INTERVAL_MS,
  MiningReminderWorker,
} from './mining-reminder.worker';

describe('MiningReminderWorker', () => {
  const originalNodeEnv = process.env.NODE_ENV;
  const settings: Record<string, unknown> = {};
  const configService = {
    get: jest.fn((key: string, fallback?: unknown) =>
      key in settings ? settings[key] : fallback,
    ),
  };
  const databaseHealthService = { isDatabaseHealthy: jest.fn() };
  const sweepService = { sweep: jest.fn() };

  let worker: MiningReminderWorker;

  beforeEach(() => {
    jest.useFakeTimers();
    jest.clearAllMocks();
    for (const key of Object.keys(settings)) delete settings[key];
    databaseHealthService.isDatabaseHealthy.mockResolvedValue(true);
    sweepService.sweep.mockResolvedValue({
      readySent: 0,
      expiringSent: 0,
      settledCycles: 0,
    });
    worker = new MiningReminderWorker(
      configService as any,
      databaseHealthService as any,
      sweepService as any,
    );
  });

  afterEach(() => {
    worker.onModuleDestroy();
    process.env.NODE_ENV = originalNodeEnv;
    jest.useRealTimers();
  });

  it('never schedules itself under Jest', async () => {
    process.env.NODE_ENV = 'test';
    worker.onModuleInit();

    await jest.advanceTimersByTimeAsync(3 * MINING_REMINDER_INTERVAL_MS);

    expect(sweepService.sweep).not.toHaveBeenCalled();
  });

  it('stays off when MINING_REMINDERS_ENABLED is false', async () => {
    process.env.NODE_ENV = 'development';
    settings.MINING_REMINDERS_ENABLED = false;
    worker.onModuleInit();

    await jest.advanceTimersByTimeAsync(3 * MINING_REMINDER_INTERVAL_MS);

    expect(sweepService.sweep).not.toHaveBeenCalled();
  });

  it('sweeps on warm start and then every 5 minutes', async () => {
    process.env.NODE_ENV = 'development';
    worker.onModuleInit();

    await jest.advanceTimersByTimeAsync(15_000);
    expect(sweepService.sweep).toHaveBeenCalledTimes(1);

    await jest.advanceTimersByTimeAsync(2 * MINING_REMINDER_INTERVAL_MS);
    expect(sweepService.sweep).toHaveBeenCalledTimes(3);
    expect(sweepService.sweep.mock.calls[0][1]).toEqual({ batchSize: 200 });
  });

  it('stops when the module is destroyed', async () => {
    process.env.NODE_ENV = 'development';
    worker.onModuleInit();
    worker.onModuleDestroy();

    await jest.advanceTimersByTimeAsync(3 * MINING_REMINDER_INTERVAL_MS);

    expect(sweepService.sweep).not.toHaveBeenCalled();
  });

  it('skips the sweep while the database is unavailable', async () => {
    databaseHealthService.isDatabaseHealthy.mockResolvedValue(false);

    await worker.tick();

    expect(sweepService.sweep).not.toHaveBeenCalled();
  });

  it('does not overlap a sweep that is still running', async () => {
    let release: () => void = () => undefined;
    sweepService.sweep.mockReturnValue(
      new Promise((resolve) => {
        release = () => resolve({});
      }),
    );

    const first = worker.tick();
    await jest.advanceTimersByTimeAsync(0);
    await worker.tick();
    release();
    await first;

    expect(sweepService.sweep).toHaveBeenCalledTimes(1);
  });

  it('survives a failing sweep', async () => {
    sweepService.sweep.mockRejectedValueOnce(new Error('db down'));

    await expect(worker.tick()).resolves.toBeUndefined();
    await worker.tick();

    expect(sweepService.sweep).toHaveBeenCalledTimes(2);
  });
});
