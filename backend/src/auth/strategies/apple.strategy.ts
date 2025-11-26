import { PassportStrategy } from '@nestjs/passport';
import { Strategy } from 'passport-apple';
import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AuthService } from '../auth.service';
import { AuthProvider } from '../../users/entities/user.entity';

@Injectable()
export class AppleStrategy extends PassportStrategy(Strategy, 'apple') {
  constructor(
    private authService: AuthService,
    private configService: ConfigService,
  ) {
    super({
      clientID: configService.get('APPLE_CLIENT_ID'),
      teamID: configService.get('APPLE_TEAM_ID'),
      keyID: configService.get('APPLE_KEY_ID'),
      privateKeyString: configService.get('APPLE_PRIVATE_KEY'),
      callbackURL: configService.get('APPLE_CALLBACK_URL') || 'http://localhost:3000/api/auth/apple/callback',
      scope: ['email', 'name'],
    });
  }

  async validate(
    accessToken: string,
    refreshToken: string,
    idToken: any,
    profile: any,
    done: (error: any, user?: any) => void,
  ): Promise<any> {
    const { id, email, name } = profile;

    const oauthProfile = {
      id,
      email: email || idToken.email,
      firstName: name?.firstName,
      lastName: name?.lastName,
      displayName: name ? `${name.firstName} ${name.lastName}`.trim() : email,
    };

    try {
      const user = await this.authService.validateOAuthUser(
        oauthProfile,
        AuthProvider.APPLE,
      );
      done(null, user);
    } catch (error) {
      done(error, false);
    }
  }
}
