import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsNotEmpty, IsOptional, IsString, MaxLength } from 'class-validator';

export class StartHandoverDto {
  @ApiProperty({
    description:
      'The hunter taking over: a username (a leading @ is ignored) or a profile id.',
    example: 'abtoonzz',
  })
  @IsString()
  @IsNotEmpty()
  @MaxLength(100)
  hunter!: string;

  @ApiPropertyOptional({ maxLength: 500 })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  note?: string;
}
