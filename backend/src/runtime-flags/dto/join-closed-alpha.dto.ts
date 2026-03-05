import { IsEmail } from 'class-validator';

export class JoinClosedAlphaDto {
  @IsEmail()
  email!: string;
}
