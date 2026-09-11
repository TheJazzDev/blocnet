import { Prisma } from '@prisma/client';
import { currentLevelSelect, toCurrentLevelDto } from './level-summary';

describe('level-summary', () => {
  const level = {
    id: 'level-2',
    slug: 'contributor',
    name: 'Contributor',
    description: 'Active member',
    iconUrl: 'https://cdn.example/levels/contributor.png',
    level: 2,
    requiredBnp: BigInt('12345678901234567890'),
    requiredComments: 10,
    requiredDaysActive: 7,
    requiredQuests: 2,
    requiredUpdates: 1,
    requiredProjects: 0,
    color: '#00ff00',
    isActive: true,
    sortOrder: 2,
  };

  it('exposes a select covering every field of the DTO and nothing more', () => {
    expect(Object.keys(currentLevelSelect).sort()).toEqual(
      Object.keys(level).sort(),
    );
    // createdAt/updatedAt are intentionally excluded from the public shape.
    expect(currentLevelSelect).not.toHaveProperty('createdAt');
    expect(currentLevelSelect).not.toHaveProperty('updatedAt');
    // Compile-time guard: the select must be a valid Prisma UserLevelSelect.
    const typed: Prisma.UserLevelSelect = currentLevelSelect;
    expect(typed).toBeDefined();
  });

  it('serializes BigInt requiredBnp as a string and keeps the other fields', () => {
    const dto = toCurrentLevelDto(level);

    expect(dto).toEqual({
      id: 'level-2',
      slug: 'contributor',
      name: 'Contributor',
      description: 'Active member',
      iconUrl: 'https://cdn.example/levels/contributor.png',
      level: 2,
      requiredBnp: '12345678901234567890',
      requiredComments: 10,
      requiredDaysActive: 7,
      requiredQuests: 2,
      requiredUpdates: 1,
      requiredProjects: 0,
      color: '#00ff00',
      isActive: true,
      sortOrder: 2,
    });
    expect(typeof dto?.requiredBnp).toBe('string');
    // The DTO must be JSON-serializable (no BigInt left behind).
    expect(() => JSON.stringify(dto)).not.toThrow();
  });

  it('returns null for a missing level', () => {
    expect(toCurrentLevelDto(null)).toBeNull();
    expect(toCurrentLevelDto(undefined)).toBeNull();
  });

  it('drops extra fields from a full UserLevel record', () => {
    const dto = toCurrentLevelDto({
      ...level,
      createdAt: new Date(),
      updatedAt: new Date(),
    } as typeof level);

    expect(dto).not.toHaveProperty('createdAt');
    expect(dto).not.toHaveProperty('updatedAt');
  });
});
