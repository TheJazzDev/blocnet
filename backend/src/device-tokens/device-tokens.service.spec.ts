import { DeviceTokensService } from './device-tokens.service';
import { PrismaService } from '../prisma/prisma.service';

describe('DeviceTokensService', () => {
  const deviceToken = {
    upsert: jest.fn(),
    findFirst: jest.fn(),
    delete: jest.fn(),
  };

  const prisma = { deviceToken } as unknown as PrismaService;

  let service: DeviceTokensService;

  beforeEach(() => {
    jest.clearAllMocks();
    service = new DeviceTokensService(prisma);
  });

  describe('register', () => {
    it('upserts on the unique token and re-points it at the current user', async () => {
      deviceToken.upsert.mockResolvedValue({ id: 'row-1' });

      await service.register('user-1', {
        token: 'fcm-token',
        platform: 'android',
      });

      const args = deviceToken.upsert.mock.calls[0][0];
      expect(args.where).toEqual({ token: 'fcm-token' });
      expect(args.update.userId).toBe('user-1');
      expect(args.create).toMatchObject({
        userId: 'user-1',
        token: 'fcm-token',
        platform: 'android',
      });
    });
  });

  describe('remove', () => {
    it('scopes the lookup to the caller', async () => {
      deviceToken.findFirst.mockResolvedValue({ id: 'row-1' });

      const result = await service.remove('user-1', 'row-1');

      expect(deviceToken.findFirst).toHaveBeenCalledWith({
        where: { id: 'row-1', userId: 'user-1' },
        select: { id: true },
      });
      expect(deviceToken.delete).toHaveBeenCalledWith({
        where: { id: 'row-1' },
      });
      expect(result).toEqual({ deleted: true });
    });

    it('does not delete a row owned by another user', async () => {
      deviceToken.findFirst.mockResolvedValue(null);

      const result = await service.remove('user-1', 'row-owned-by-user-2');

      expect(deviceToken.delete).not.toHaveBeenCalled();
      expect(result).toEqual({ deleted: false });
    });
  });

  describe('removeByToken', () => {
    it('deletes the caller own token by value', async () => {
      deviceToken.findFirst.mockResolvedValue({ id: 'row-1' });

      const result = await service.removeByToken('user-1', 'fcm-token');

      expect(deviceToken.findFirst).toHaveBeenCalledWith({
        where: { token: 'fcm-token', userId: 'user-1' },
        select: { id: true },
      });
      expect(deviceToken.delete).toHaveBeenCalledWith({
        where: { id: 'row-1' },
      });
      expect(result).toEqual({ deleted: true });
    });

    it('refuses to unregister a token belonging to another user', async () => {
      // The token exists in the table but is owned by user-2, so the
      // userId-scoped lookup finds nothing.
      deviceToken.findFirst.mockResolvedValue(null);

      const result = await service.removeByToken(
        'user-1',
        'token-owned-by-user-2',
      );

      expect(deviceToken.findFirst).toHaveBeenCalledWith({
        where: { token: 'token-owned-by-user-2', userId: 'user-1' },
        select: { id: true },
      });
      expect(deviceToken.delete).not.toHaveBeenCalled();
      expect(result).toEqual({ deleted: false });
    });

    it('reports an unknown token the same way as a foreign one', async () => {
      deviceToken.findFirst.mockResolvedValue(null);

      const result = await service.removeByToken('user-1', 'never-registered');

      expect(result).toEqual({ deleted: false });
    });
  });
});
