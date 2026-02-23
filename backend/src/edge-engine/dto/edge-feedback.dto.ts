import { IsEnum, IsObject, IsOptional, IsString } from 'class-validator';

export enum EdgeFeedbackAction {
  act = 'act',
  watch = 'watch',
  ignore = 'ignore',
}

export class EdgeFeedbackDto {
  @IsString()
  decisionId!: string;

  @IsEnum(EdgeFeedbackAction)
  action!: EdgeFeedbackAction;

  @IsOptional()
  @IsObject()
  context?: Record<string, unknown>;
}
