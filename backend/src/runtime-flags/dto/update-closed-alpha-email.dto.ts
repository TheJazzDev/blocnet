import { IsBoolean } from 'class-validator';

export class UpdateClosedAlphaEmailDto {
  @IsBoolean()
  isActive!: boolean;
}
