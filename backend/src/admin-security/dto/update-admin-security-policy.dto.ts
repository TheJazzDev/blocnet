import { IsBoolean } from 'class-validator';

export class UpdateAdminSecurityPolicyDto {
  @IsBoolean()
  require2faForAdminPanel!: boolean;
}
