import { writeFileSync } from 'fs';
import { join } from 'path';

const levels = [
  { level: 1, name: 'newcomer', color: '#6B7280', shape: 'circle' },
  { level: 2, name: 'explorer', color: '#6366F1', shape: 'square' },
  { level: 3, name: 'member', color: '#3B82F6', shape: 'hexagon' },
  { level: 4, name: 'contributor', color: '#10B981', shape: 'triangle' },
  { level: 5, name: 'builder', color: '#14B8A6', shape: 'diamond' },
  { level: 6, name: 'advocate', color: '#06B6D4', shape: 'star' },
  { level: 7, name: 'veteran', color: '#8B5CF6', shape: 'shield' },
  { level: 8, name: 'champion', color: '#A855F7', shape: 'crown' },
  { level: 9, name: 'elite', color: '#C084FC', shape: 'gem' },
  { level: 10, name: 'expert', color: '#F59E0B', shape: 'badge' },
  { level: 11, name: 'guardian', color: '#FBBF24', shape: 'medallion' },
  { level: 12, name: 'master', color: '#FCD34D', shape: 'trophy' },
  { level: 13, name: 'legend', color: '#EF4444', shape: 'flame' },
  { level: 14, name: 'titan', color: '#DC2626', shape: 'lightning' },
  { level: 15, name: 'pioneer', color: '#B91C1C', shape: 'infinity' },
];

const shapes = {
  circle: (color: string) => `<circle cx="64" cy="64" r="44" fill="${color}"/>`,
  square: (color: string) => `<rect x="24" y="24" width="80" height="80" rx="8" fill="${color}"/>`,
  hexagon: (color: string) => `<polygon points="64,20 98,40 98,88 64,108 30,88 30,40" fill="${color}"/>`,
  triangle: (color: string) => `<polygon points="64,20 108,98 20,98" fill="${color}"/>`,
  diamond: (color: string) => `<polygon points="64,20 108,64 64,108 20,64" fill="${color}"/>`,
  star: (color: string) => `<polygon points="64,20 76,52 110,52 82,74 94,106 64,84 34,106 46,74 18,52 52,52" fill="${color}"/>`,
  shield: (color: string) => `<path d="M 64 20 L 104 40 L 104 70 Q 104 90 64 108 Q 24 90 24 70 L 24 40 Z" fill="${color}"/>`,
  crown: (color: string) => `<path d="M 30 75 L 40 45 L 50 65 L 64 40 L 78 65 L 88 45 L 98 75 L 95 95 L 33 95 Z" fill="${color}"/>`,
  gem: (color: string) => `<path d="M 44 40 L 64 20 L 84 40 L 94 50 L 64 100 L 34 50 Z" fill="${color}"/>`,
  badge: (color: string) => `<circle cx="64" cy="64" r="40" fill="${color}"/><circle cx="64" cy="64" r="30" fill="none" stroke="white" stroke-width="3"/>`,
  medallion: (color: string) => `<circle cx="64" cy="70" r="38" fill="${color}"/><rect x="54" y="20" width="20" height="30" fill="${color}"/>`,
  trophy: (color: string) => `<path d="M 40 40 L 40 50 Q 40 65 50 65 L 55 65 L 55 85 L 48 85 L 48 95 L 80 95 L 80 85 L 73 85 L 73 65 L 78 65 Q 88 65 88 50 L 88 40 Z M 35 35 L 35 52 Q 35 60 40 60 M 93 35 L 93 52 Q 93 60 88 60" fill="${color}"/>`,
  flame: (color: string) => `<path d="M 64 20 Q 74 35 74 50 Q 74 60 70 68 Q 76 62 80 55 Q 84 65 84 75 Q 84 95 64 108 Q 44 95 44 75 Q 44 60 52 50 Q 52 40 64 20 Z" fill="${color}"/>`,
  lightning: (color: string) => `<path d="M 70 20 L 50 60 L 65 60 L 55 108 L 90 55 L 72 55 Z" fill="${color}"/>`,
  infinity: (color: string) => `<path d="M 36 64 Q 36 44 48 44 Q 56 44 64 54 Q 72 44 80 44 Q 92 44 92 64 Q 92 84 80 84 Q 72 84 64 74 Q 56 84 48 84 Q 36 84 36 64 Z" fill="${color}"/>`,
};

for (const { level, name, color, shape } of levels) {
  const shapeElement = shapes[shape as keyof typeof shapes](color);

  const svg = `<svg width="128" height="128" viewBox="0 0 128 128" fill="none" xmlns="http://www.w3.org/2000/svg">
  ${shapeElement}
  <text x="64" y="78" font-family="Arial, sans-serif" font-size="32" font-weight="900" fill="white" text-anchor="middle" dominant-baseline="middle">${level}</text>
</svg>`;

  const filename = `level-${level}-${name}.svg`;
  const filepath = join(__dirname, '../public/images/levels', filename);
  writeFileSync(filepath, svg);
  console.log(`Created ${filename}`);
}

console.log('\n✅ All level icons generated successfully!');
