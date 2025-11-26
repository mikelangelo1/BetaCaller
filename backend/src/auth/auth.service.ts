import { Injectable, UnauthorizedException, ConflictException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { UsersService } from '../users/users.service';
import { User, AuthProvider } from '../users/entities/user.entity';
import { CreateUserDto } from '../users/dto/create-user.dto';

interface JwtPayload {
  sub: string;
  email: string;
  iat?: number;
  exp?: number;
}

interface AuthTokens {
  accessToken: string;
  refreshToken: string;
}

interface OAuthProfile {
  id: string;
  email: string;
  firstName?: string;
  lastName?: string;
  displayName?: string;
  profileImageUrl?: string;
}

@Injectable()
export class AuthService {
  constructor(
    private usersService: UsersService,
    private jwtService: JwtService,
  ) {}

  async register(createUserDto: CreateUserDto): Promise<User> {
    try {
      const user = await this.usersService.create(createUserDto);
      await this.usersService.updateLastLogin(user.id);
      return user;
    } catch (error) {
      if (error instanceof ConflictException) {
        throw error;
      }
      throw new Error('Registration failed');
    }
  }

  async validateUser(email: string, password: string): Promise<User | null> {
    const user = await this.usersService.findByEmail(email);

    if (!user || user.authProvider !== AuthProvider.LOCAL) {
      return null;
    }

    const isPasswordValid = await user.validatePassword(password);

    if (!isPasswordValid) {
      return null;
    }

    if (!user.isActive) {
      throw new UnauthorizedException('Account has been deactivated');
    }

    await this.usersService.updateLastLogin(user.id);
    return user;
  }

  async login(user: User): Promise<AuthTokens> {
    const payload: JwtPayload = {
      sub: user.id,
      email: user.email,
    };

    const accessToken = this.jwtService.sign(payload);
    const refreshToken = this.jwtService.sign(payload, {
      expiresIn: '30d',
    });

    return {
      accessToken,
      refreshToken,
    };
  }

  async validateOAuthUser(
    profile: OAuthProfile,
    provider: AuthProvider,
  ): Promise<User> {
    let user: User | null = null;

    // Check if user exists by provider-specific ID
    switch (provider) {
      case AuthProvider.GOOGLE:
        user = await this.usersService.findByGoogleId(profile.id);
        break;
      case AuthProvider.APPLE:
        user = await this.usersService.findByAppleId(profile.id);
        break;
      default:
        throw new Error(`Unsupported auth provider: ${provider}`);
    }

    // If user exists, update last login and return
    if (user) {
      await this.usersService.updateLastLogin(user.id);
      return user;
    }

    // Check if user exists by email
    user = await this.usersService.findByEmail(profile.email);

    // If user exists with different provider, link the accounts
    if (user) {
      const updateData: any = {};

      switch (provider) {
        case AuthProvider.GOOGLE:
          updateData.googleId = profile.id;
          break;
        case AuthProvider.APPLE:
          updateData.appleId = profile.id;
          break;
      }

      user = await this.usersService.update(user.id, updateData);
      await this.usersService.updateLastLogin(user.id);
      return user;
    }

    // Create new user
    const createUserDto: CreateUserDto = {
      email: profile.email,
      password: null, // OAuth users don't have passwords
      firstName: profile.firstName,
      lastName: profile.lastName,
      displayName: profile.displayName || `${profile.firstName} ${profile.lastName}`.trim(),
    };

    const newUser = await this.usersService.create(createUserDto);

    // Set provider-specific ID
    const updateData: any = { authProvider: provider };

    switch (provider) {
      case AuthProvider.GOOGLE:
        updateData.googleId = profile.id;
        break;
      case AuthProvider.APPLE:
        updateData.appleId = profile.id;
        break;
    }

    user = await this.usersService.update(newUser.id, updateData);
    await this.usersService.updateLastLogin(user.id);

    return user;
  }

  async validateJwtPayload(payload: JwtPayload): Promise<User> {
    const user = await this.usersService.findById(payload.sub);

    if (!user.isActive) {
      throw new UnauthorizedException('Account has been deactivated');
    }

    return user;
  }

  async refreshToken(refreshToken: string): Promise<AuthTokens> {
    try {
      const payload = this.jwtService.verify<JwtPayload>(refreshToken);
      const user = await this.usersService.findById(payload.sub);

      if (!user.isActive) {
        throw new UnauthorizedException('Account has been deactivated');
      }

      return this.login(user);
    } catch (error) {
      throw new UnauthorizedException('Invalid refresh token');
    }
  }
}
