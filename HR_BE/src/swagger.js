import swaggerJSDoc from 'swagger-jsdoc';

const options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'HR Recruitment API',
      version: '1.0.0',
      description: 'API documentation for HR Recruitment backend'
    },
    components: {
      securitySchemes: {
        bearerAuth: {
          type: 'http',
          scheme: 'bearer',
          bearerFormat: 'JWT'
        }
      }
    },
    servers: [
      {
        url: process.env.BASE_URL || `http://localhost:${process.env.PORT || 4000}`,
        description: 'Development server'
      }
    ]
  },
  // Adjust these globs if your route files live elsewhere or use TypeScript
  apis: ['./src/modules/**/*.js']
};

const swaggerSpec = swaggerJSDoc(options);

export default swaggerSpec;
