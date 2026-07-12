/* web/src/api/locations.ts */

import { apiRequest } from './apiClient.js';
import type { PostLocation } from './types.js';

export const locationService = {
  
   // Fetch the fixed list of valid campus locations (public endpoint).
   
  async getLocations(): Promise<{ locations: PostLocation[] }> {
    return apiRequest<{ locations: PostLocation[] }>('/locations', {
      method: 'GET',
    });
  },
};