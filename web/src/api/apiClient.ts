/* web/src/api/apiClient.ts */

// Determine API Base URL from environment variables, fallback to local dev port
const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:5001/api';

// Custom error class that holds API response payload
export class ApiError extends Error {
  status: number;
  payload: any;

  constructor(status: number, message: string, payload: any = null) {
    super(message);
    this.name = 'ApiError';
    this.status = status;
    this.payload = payload;
  }
}

interface RequestOptions extends RequestInit {
  bodyData?: any; // Convenient payload helper
}

/**
 * Perform an authenticated API request using fetch.
 */
export async function apiRequest<T = any>(
  path: string,
  options: RequestOptions = {}
): Promise<T> {
  const { bodyData, headers = {}, ...restOptions } = options;
  
  // Clean up path prefix if provided
  const cleanPath = path.startsWith('/') ? path.slice(1) : path;
  const url = `${API_BASE_URL}/${cleanPath}`;

  const requestHeaders = new Headers(headers);

  // Auto-inject JSON Content-Type if we're sending body data
  if (bodyData && !requestHeaders.has('Content-Type')) {
    requestHeaders.set('Content-Type', 'application/json');
  }

  // Auto-inject JWT token if saved in localStorage
  const token = localStorage.getItem('auth_token');
  if (token && !requestHeaders.has('Authorization')) {
    requestHeaders.set('Authorization', `Bearer ${token}`);
  }

  const fetchOptions: RequestInit = {
    ...restOptions,
    headers: requestHeaders,
  };

  if (bodyData) {
    fetchOptions.body = JSON.stringify(bodyData);
  }

  const response = await fetch(url, fetchOptions);

  // Check if content is JSON
  const contentType = response.headers.get('Content-Type');
  let data: any = null;
  if (contentType && contentType.includes('application/json')) {
    data = await response.json();
  } else {
    data = { message: await response.text() };
  }

  if (!response.ok) {
    // If we receive a 401 Unauthorized, dispatch a custom event to notify AuthContext
    if (response.status === 401) {
      window.dispatchEvent(new CustomEvent('auth-unauthorized'));
    }

    const errorMessage = data?.error || data?.message || `Request failed with status ${response.status}`;
    throw new ApiError(response.status, errorMessage, data);
  }

  return data as T;
}
