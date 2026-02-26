import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsOptional, IsString, IsUUID } from 'class-validator';

export class BlockUserDto {
  @ApiProperty({
    description: 'ID of the user to block',
    example: '550e8400-e29b-41d4-a716-446655440000',
  })
  @IsUUID()
  @IsNotEmpty()
  blockedId: string;

  @ApiProperty({
    description: 'Optional reason for blocking',
    example: 'Spam or inappropriate behavior',
    required: false,
  })
  @IsString()
  @IsOptional()
  reason?: string;
}
