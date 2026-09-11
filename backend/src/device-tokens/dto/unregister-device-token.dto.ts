import { IsOptional, IsString, MaxLength } from 'class-validator';

/**
 * Token-value carrier for `DELETE /device-tokens`.
 *
 * The field is optional on the DTO because the value may arrive either as a
 * query parameter or in the request body; the controller requires exactly one
 * of the two to be present.
 */
export class UnregisterDeviceTokenDto {
  @IsOptional()
  @IsString()
  @MaxLength(4096)
  token?: string;
}
