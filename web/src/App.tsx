/* web/src/App.tsx */

import { AuthProvider } from './context/AuthContext.js';
import { AppRouter } from './router/AppRouter.js';

function App() {
  return (
    <AuthProvider>
      <AppRouter />
    </AuthProvider>
  );
}

export default App;
