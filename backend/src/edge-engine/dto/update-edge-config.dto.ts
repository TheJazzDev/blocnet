import { IsBoolean, IsInt, IsOptional, IsString, IsUrl, Max, Min } from 'class-validator';

export class UpdateEdgeConfigDto {
  @IsOptional()
  @IsBoolean()
  enabled?: boolean;

  @IsOptional()
  @IsBoolean()
  mlEnabled?: boolean;

  @IsOptional()
  @IsUrl({
    require_protocol: true,
    require_tld: false,
  })
  mlUrl?: string;

  @IsOptional()
  @IsInt()
  @Min(1000)
  @Max(300000)
  mlTimeout?: number;

  @IsOptional()
  @IsString()
  mlProvider?: string;

  @IsOptional()
  @IsBoolean()
  mlWebSearch?: boolean;

  @IsOptional()
  @IsString()
  mlOllamaModel?: string;

  @IsOptional()
  @IsString()
  mlOllamaEmbeddingModel?: string;

  @IsOptional()
  @IsInt()
  @Min(1000)
  @Max(300000)
  mlOllamaTimeout?: number;

  @IsOptional()
  @IsString()
  mlGroqModel?: string;

  @IsOptional()
  @IsString()
  mlGeminiModel?: string;

  @IsOptional()
  @IsString()
  mlGeminiEmbeddingModel?: string;

  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(2592000)
  mlCacheTtl?: number;

  @IsOptional()
  @IsInt()
  @Min(1000)
  @Max(100000)
  mlMaxContentLength?: number;
}
