import { ConfigService } from '@nestjs/config';
import { LevelIconStorageService } from './level-icon-storage.service';

describe('LevelIconStorageService', () => {
  const createService = () => {
    const values: Record<string, string> = {
      SUPABASE_URL: 'https://example.supabase.co',
      SUPABASE_LEVEL_BADGES_BUCKET: 'level-badges',
      SUPABASE_SECRET_KEY: 'service-key',
    };
    const configService = {
      get: jest.fn((key: string) => values[key]),
    } as unknown as ConfigService;
    return new LevelIconStorageService(configService);
  };

  it('deletes previous managed icon when icon changes', async () => {
    const service = createService();
    const remove = jest.fn().mockResolvedValue({ error: null });
    const from = jest.fn(() => ({ remove }));
    (service as any).supabaseStorageClient = { storage: { from } };

    await service.deletePreviousLevelIconIfManaged(
      'https://example.supabase.co/storage/v1/object/public/level-badges/levels/lvl-1/old%20icon.svg',
      'https://example.supabase.co/storage/v1/object/public/level-badges/levels/lvl-1/new-icon.svg',
    );

    expect(from).toHaveBeenCalledWith('level-badges');
    expect(remove).toHaveBeenCalledWith(['levels/lvl-1/old icon.svg']);
  });

  it('does not delete when previous and current resolve to the same object path', async () => {
    const service = createService();
    const remove = jest.fn().mockResolvedValue({ error: null });
    const from = jest.fn(() => ({ remove }));
    (service as any).supabaseStorageClient = { storage: { from } };

    await service.deletePreviousLevelIconIfManaged(
      'https://example.supabase.co/storage/v1/object/public/level-badges/levels/lvl-2/icon.svg?version=1',
      'https://example.supabase.co/storage/v1/object/sign/level-badges/levels/lvl-2/icon.svg?token=abc',
    );

    expect(remove).not.toHaveBeenCalled();
  });

  it('ignores non-managed URLs', async () => {
    const service = createService();
    const remove = jest.fn().mockResolvedValue({ error: null });
    const from = jest.fn(() => ({ remove }));
    (service as any).supabaseStorageClient = { storage: { from } };

    await service.deletePreviousLevelIconIfManaged(
      'https://cdn.example.com/level-2.svg',
      'https://example.supabase.co/storage/v1/object/public/level-badges/levels/lvl-2/new-icon.svg',
    );

    expect(remove).not.toHaveBeenCalled();
  });
});
