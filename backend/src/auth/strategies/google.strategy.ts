import { PassportStrategy } from '@nestjs/passport';
import { Strategy, VerifyCallback } from 'passport-google-oauth20';
import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AuthService } from '../auth.service';
import { AuthProvider } from '../../users/entities/user.entity';

@Injectable()
export class GoogleStrategy extends PassportStrategy(Strategy, 'google') {
  constructor(
    private authService: AuthService,
    private configService: ConfigService,
  ) {
    super({
      clientID: configService.get('GOOGLE_CLIENT_ID'),
      clientSecret: configService.get('GOOGLE_CLIENT_SECRET'),
      callbackURL: configService.get('GOOGLE_CALLBACK_URL') || 'http://localhost:3000/api/auth/google/callback',
      scope: ['email', 'profile'],
    });
  }

  async validate(
    accessToken: string,
    refreshToken: string,
    profile: any,
    done: VerifyCallback,
  ): Promise<any> {
    const { id, emails, name, photos } = profile;

    const oauthProfile = {
      id,
      email: emails[0].value,
      firstName: name.givenName,
      lastName: name.familyName,
      displayName: profile.displayName,
      profileImageUrl: photos?.[0]?.value,
    };

    try {
      const user = await this.authService.validateOAuthUser(
        oauthProfile,
        AuthProvider.GOOGLE,
      );
      done(null, user);
    } catch (error) {
      done(error, false);
    }
  }
}
