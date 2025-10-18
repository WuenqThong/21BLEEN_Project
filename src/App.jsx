import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate, useParams } from 'react-router-dom';
import { AuthProvider, useAuth } from './context/AuthContext';
import { ProtectedRoute, PublicRoute } from './components/ProtectedRoute';
import EmailLoginPage from './components/EmailLoginPage';
import HomePage from './components/HomePage';
import UnlockPage from './components/UnlockPage';
import HomeAfterUnlock from './components/HomeAfterUnlock';
import SettingsPage from './components/SettingsPage';
import ImagesPage from './components/ImagesPage';
import VideoPage from './components/VideoPage';
import MessagesPage from './components/MessagesPage';
import AdminLogin from './components/AdminLogin';
import AdminPage from './components/AdminPage';
import { ToastContainer } from 'react-toastify';
import 'react-toastify/dist/ReactToastify.css';

// Error Boundary Component
class ErrorBoundary extends React.Component {
  constructor(props) {
    super(props);
    this.state = { hasError: false, error: null };
  }

  static getDerivedStateFromError(error) {
    return { hasError: true, error };
  }

  componentDidCatch(error, errorInfo) {
    console.error('App Error:', error, errorInfo);
  }

  render() {
    if (this.state.hasError) {
      return (
        <div className="min-h-screen flex items-center justify-center bg-gray-100">
          <div className="text-center">
            <h1 className="text-2xl font-bold text-red-600 mb-4">Có lỗi xảy ra</h1>
            <p className="text-gray-600 mb-4">Vui lòng thử lại sau</p>
            <button 
              onClick={() => window.location.reload()} 
              className="bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600"
            >
              Tải lại trang
            </button>
          </div>
        </div>
      );
    }

    return this.props.children;
  }
}


const AppRoutes = () => {
  return (
    <Routes>
      {/* Email login page - root route */}
      <Route path="/" element={<EmailLoginPage />} />
      
      {/* Unlock page - public route */}
      <Route path="/:userId/unlock" element={
        <PublicRoute>
          <UnlockPage />
        </PublicRoute>
      } />
      
      {/* Default userId route - show HomePage first */}
      <Route path="/:userId" element={<HomePage />} />
      
      {/* Protected routes */}
      <Route path="/:userId/home" element={
        <ProtectedRoute>
          <HomeAfterUnlock />
        </ProtectedRoute>
      } />
      
      <Route path="/:userId/settings" element={
        <ProtectedRoute>
          <SettingsPage />
        </ProtectedRoute>
      } />
      
      <Route path="/:userId/images" element={
        <ProtectedRoute>
          <ImagesPage />
        </ProtectedRoute>
      } />
      
      <Route path="/:userId/video" element={
        <ProtectedRoute>
          <VideoPage />
        </ProtectedRoute>
      } />
      
      <Route path="/:userId/messages" element={
        <ProtectedRoute>
          <MessagesPage />
        </ProtectedRoute>
      } />
      
      {/* Admin routes */}
      <Route path="/admin" element={<AdminLogin />} />
      <Route path="/admin/dashboard" element={<AdminPage />} />
      
      {/* Catch all other routes */}
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
};

function App() {
  return (
    <ErrorBoundary>
      <Router>
        <AuthProvider>
          <AppRoutes />
          <ToastContainer
            position="top-center"
            autoClose={3000}
            hideProgressBar={false}
            newestOnTop
            closeOnClick
            pauseOnFocusLoss
            draggable
            pauseOnHover
            theme="light"
          />
        </AuthProvider>
      </Router>
    </ErrorBoundary>
  );
}

export default App;
