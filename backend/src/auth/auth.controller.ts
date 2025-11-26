import {
  Controller,
  Post,
  Get,
  Body,
  UseGuards,
  Request,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { AuthService } from './auth.service';
import { CreateUserDto } from '../users/dto/create-user.dto';
import { LocalAuthGuard } from './guards/local-auth.guard';
import { JwtAuthGuard } from './guards/jwt-auth.guard';
import { GoogleAuthGuard } from './guards/google-auth.guard';
import { AppleAuthGuard } from './guards/apple-auth.guard';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('register')
  async register(@Body() createUserDto: CreateUserDto) {
    const user = await this.authService.register(createUserDto);
    const tokens = await this.authService.login(user);

    return {
      user: user.toSafeObject(),
      ...tokens,
    };
  }

  @UseGuards(LocalAuthGuard)
  @Post('login')
  @HttpCode(HttpStatus.OK)
  async login(@Request() req) {
    const tokens = await this.authService.login(req.user);

    return {
      user: req.user.toSafeObject(),
      ...tokens,
    };
  }

  @Post('refresh')
  @HttpCode(HttpStatus.OK)
  async refresh(@Body('refreshToken') refreshToken: string) {
    const tokens = await this.authService.refreshToken(refreshToken);

    return tokens;
  }

  @Get('google')
  @UseGuards(GoogleAuthGuard)
  async googleAuth() {
    // Initiates Google OAuth flow
    // Guard will redirect to Google
  }

  @Get('google/callback')
  @UseGuards(GoogleAuthGuard)
  async googleAuthCallback(@Request() req) {
    const tokens = await this.authService.login(req.user);

    return {
      user: req.user.toSafeObject(),
      ...tokens,
    };
  }

  @Get('apple')
  @UseGuards(AppleAuthGuard)
  async appleAuth() {
    // Initiates Apple OAuth flow
    // Guard will redirect to Apple
  }

  @Get('apple/callback')
  @UseGuards(AppleAuthGuard)
  async appleAuthCallback(@Request() req) {
    const tokens = await this.authService.login(req.user);

    return {
      user: req.user.toSafeObject(),
      ...tokens,
    };
  }

  @UseGuards(JwtAuthGuard)
  @Get('me')
  async getProfile(@Request() req) {
    return req.user.toSafeObject();
  }

  @UseGuards(JwtAuthGuard)
  @Post('logout')
  @HttpCode(HttpStatus.OK)
  async logout() {
    // For JWT, logout is handled client-side by removing tokens
    // This endpoint can be used for additional cleanup if needed
    return {
      message: 'Logged out successfully',
    };
  }
}
