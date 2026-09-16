import { ApiProperty } from '@nestjs/swagger';
import { ArrayMaxSize, IsArray, IsString } from 'class-validator';

export const UPDATE_REACTIONS_IMPORT_MAX = 500;

/**
 * The phone's old local likes and saves, sent once so they survive the move
 * to the server. Ids are plain strings on purpose: local storage may hold ids
 * that never were real updates, and those are ignored rather than rejected.
 */
export class ImportUpdateReactionsDto {
  @ApiProperty({ type: [String], maxItems: UPDATE_REACTIONS_IMPORT_MAX })
  @IsArray()
  @ArrayMaxSize(UPDATE_REACTIONS_IMPORT_MAX)
  @IsString({ each: true })
  likedUpdateIds!: string[];

  @ApiProperty({ type: [String], maxItems: UPDATE_REACTIONS_IMPORT_MAX })
  @IsArray()
  @ArrayMaxSize(UPDATE_REACTIONS_IMPORT_MAX)
  @IsString({ each: true })
  bookmarkedUpdateIds!: string[];
}
