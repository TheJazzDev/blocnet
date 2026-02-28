import {
  Body,
  Controller,
  Get,
  Headers,
  Patch,
  Post,
  UnauthorizedException,
  UseGuards,
} from '@nestjs/common';
import { AuditLogService } from '../audit-log/audit-log.service';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { AppRole } from '../common/enums/role.enum';
import { AuthGuard } from '../common/guards/auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import type { AuthUser } from '../common/interfaces/auth-user.interface';
import { ConfirmAdminTotpDto } from './dto/confirm-admin-totp.dto';
import { UpdateAdminSecurityPolicyDto } from './dto/update-admin-security-policy.dto';
import { VerifyAdminTotpDto } from './dto/verify-admin-totp.dto';
import { AdminTwoFactorService } from './admin-two-factor.service';

@Controller('admin/security/2fa')
@UseGuards(AuthGuard, RolesGuard)
export class AdminTwoFactorController {
  constructor(
    private readonly adminTwoFactorService: AdminTwoFactorService,
    private readonly auditLogService: AuditLogService,
  ) {}

  @Get('preflight')
  async getPreflight(@CurrentUser() user: AuthUser | undefined) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.adminTwoFactorService.getPreflight(user.id, user.realRoles ?? user.roles);
  }

  @Get('policy')
  @Roles(AppRole.OWNER, AppRole.ADMIN, AppRole.MODERATOR)
  async getPolicy(@CurrentUser() user: AuthUser | undefined) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    const [policy, summary] = await Promise.all([
      this.adminTwoFactorService.getPolicy(),
      this.adminTwoFactorService.getPolicySummary(),
    ]);

    await this.auditLogService.create({
      actorId: user.id,
      action: 'security.2fa.policy.view',
      resourceType: 'admin_security_policy',
      resourceId: policy.id,
    });

    return {
      ...policy,
      summary,
    };
  }

  @Patch('policy')
  @Roles(AppRole.OWNER)
  async updatePolicy(
    @CurrentUser() user: AuthUser | undefined,
    @Body() dto: UpdateAdminSecurityPolicyDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    const policy = await this.adminTwoFactorService.updatePolicy({
      actorId: user.id,
      require2faForAdminPanel: dto.require2faForAdminPanel,
    });

    const summary = await this.adminTwoFactorService.getPolicySummary();

    await this.auditLogService.create({
      actorId: user.id,
      action: 'security.2fa.policy.update',
      resourceType: 'admin_security_policy',
      resourceId: policy.id,
      metadata: {
        require2faForAdminPanel: policy.require2faForAdminPanel,
        summary,
      },
    });

    return {
      ...policy,
      summary,
    };
  }

  @Post('enrollment/start')
  async startEnrollment(@CurrentUser() user: AuthUser | undefined) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    const result = await this.adminTwoFactorService.startEnrollment({
      userId: user.id,
      email: user.email,
      roles: user.realRoles ?? user.roles,
    });

    await this.auditLogService.create({
      actorId: user.id,
      action: 'security.2fa.enrollment.start',
      resourceType: 'admin_2fa',
      resourceId: user.id,
      metadata: {
        expiresAt: result.expiresAt.toISOString(),
      },
    });

    return result;
  }

  @Post('enrollment/confirm')
  async confirmEnrollment(
    @CurrentUser() user: AuthUser | undefined,
    @Body() dto: ConfirmAdminTotpDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    const result = await this.adminTwoFactorService.confirmEnrollment({
      userId: user.id,
      roles: user.realRoles ?? user.roles,
      code: dto.code,
    });

    await this.auditLogService.create({
      actorId: user.id,
      action: 'security.2fa.enrollment.confirm',
      resourceType: 'admin_2fa',
      resourceId: user.id,
      metadata: {
        recoveryCodesIssued: result.recoveryCodes.length,
        sessionExpiresAt: result.sessionExpiresAt.toISOString(),
      },
    });

    return result;
  }

  @Post('login/verify')
  async verifyLogin(
    @CurrentUser() user: AuthUser | undefined,
    @Body() dto: VerifyAdminTotpDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    const result = await this.adminTwoFactorService.verifyLoginChallenge({
      userId: user.id,
      roles: user.realRoles ?? user.roles,
      code: dto.code,
      recoveryCode: dto.recoveryCode,
    });

    await this.auditLogService.create({
      actorId: user.id,
      action: dto.recoveryCode
        ? 'security.2fa.login.verify.recovery'
        : 'security.2fa.login.verify.totp',
      resourceType: 'admin_2fa',
      resourceId: user.id,
      metadata: {
        sessionExpiresAt: result.expiresAt.toISOString(),
      },
    });

    return result;
  }

  @Post('recovery/regenerate')
  async regenerateRecoveryCodes(
    @CurrentUser() user: AuthUser | undefined,
    @Body() dto: VerifyAdminTotpDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    const result = await this.adminTwoFactorService.regenerateRecoveryCodes({
      userId: user.id,
      roles: user.realRoles ?? user.roles,
      code: dto.code,
      recoveryCode: dto.recoveryCode,
    });

    await this.auditLogService.create({
      actorId: user.id,
      action: 'security.2fa.recovery.regenerate',
      resourceType: 'admin_2fa',
      resourceId: user.id,
      metadata: {
        recoveryCodesIssued: result.recoveryCodes.length,
      },
    });

    return result;
  }

  @Post('disable')
  async disable(
    @CurrentUser() user: AuthUser | undefined,
    @Body() dto: VerifyAdminTotpDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    const result = await this.adminTwoFactorService.disableTotp({
      userId: user.id,
      roles: user.realRoles ?? user.roles,
      code: dto.code,
      recoveryCode: dto.recoveryCode,
    });

    await this.auditLogService.create({
      actorId: user.id,
      action: 'security.2fa.disable',
      resourceType: 'admin_2fa',
      resourceId: user.id,
    });

    return result;
  }

  @Post('session/validate')
  async validateSession(
    @CurrentUser() user: AuthUser | undefined,
    @Body() dto: { sessionToken?: string },
    @Headers('x-admin-2fa-session') sessionHeader?: string,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    const token = dto.sessionToken?.trim() || sessionHeader?.trim() || '';

    return this.adminTwoFactorService.validateSession({
      userId: user.id,
      roles: user.realRoles ?? user.roles,
      sessionToken: token,
    });
  }
}
