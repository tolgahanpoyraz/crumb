/* web/src/api/auth.ts */

import { apiRequest } from './apiClient.js';
import type { 
  AuthResponse, 
  MeResponse, 
  MessageResponse, 
  ChangePasswordResponse 
} from './types.js';

export const authService = {
  
  // Log in user and return JWT + user profile.
   
  async login(body: Record<string, any>): Promise<AuthResponse> {
    return apiRequest<AuthResponse>('/auth/login', {
      method: 'POST',
      bodyData: body,
    });
  },

  /**
   * Register a new account. Sends verification email.
   */
  async register(body: Record<string, any>): Promise<MessageResponse> {
    return apiRequest<MessageResponse>('/auth/register', {
      method: 'POST',
      bodyData: body,
    });
  },

  
   // Fetch current logged in user details.
  
  async getMe(): Promise<MeResponse> {
    return apiRequest<MeResponse>('/auth/me', {
      method: 'GET',
    });
  },

  
   // Resend verification email to address.
   
  async resendVerification(email: string): Promise<MessageResponse> {
    return apiRequest<MessageResponse>('/auth/resend-verification', {
      method: 'POST',
      bodyData: { email },
    });
  },

  
   // Request password reset token email.
   
  async forgotPassword(email: string): Promise<MessageResponse> {
    return apiRequest<MessageResponse>('/auth/forgot-password', {
      method: 'POST',
      bodyData: { email },
    });
  },

  
  // Submit reset password token and new password.
   
  async resetPassword(body: Record<string, any>): Promise<MessageResponse> {
    return apiRequest<MessageResponse>('/auth/reset-password', {
      method: 'POST',
      bodyData: body,
    });
  },

  
   // Change password when already logged in. Returns a fresh JWT.
   
  async changePassword(body: Record<string, any>): Promise<ChangePasswordResponse> {
    return apiRequest<ChangePasswordResponse>('/auth/change-password', {
      method: 'POST',
      bodyData: body,
    });
  },
};
