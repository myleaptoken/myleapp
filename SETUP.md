# 🚀 Configuración de MY LEAP

## 📋 Pasos para configurar el proyecto

### 1. Variables de Entorno

1. **Ve a tu proyecto en Supabase**: https://supabase.com/dashboard
2. **Selecciona tu proyecto** (o crea uno nuevo)
3. **Ve a Settings → API**
4. **Copia los valores y pégalos en `.env.local`**:

\`\`\`bash
# Busca estos valores en Supabase:
Project URL → NEXT_PUBLIC_SUPABASE_URL
anon public → NEXT_PUBLIC_SUPABASE_ANON_KEY  
service_role → SUPABASE_SERVICE_ROLE_KEY
\`\`\`

### 2. Ejecutar Scripts de Base de Datos

Una vez configuradas las variables:

1. **Reinicia el servidor**: `npm run dev`
2. **Ejecuta los scripts** haciendo clic en los botones "Run Script" en v0:
   - `create-tables.sql` (primero)
   - `seed-data.sql` (segundo)

### 3. Verificar Instalación

- **Abre Supabase Dashboard**
- **Ve a Table Editor**
- **Verifica que se crearon las tablas**:
  - users
  - facilitators
  - events
  - courses
  - testimonials
  - etc.

### 4. Probar Autenticación

1. **Ve a la landing page**
2. **Haz clic en "Iniciar Sanación"**
3. **Regístrate con un email**
4. **Verifica que te redirija al dashboard**

## 🔧 Estructura de Variables

\`\`\`env
# Públicas (visibles en el cliente)
NEXT_PUBLIC_SUPABASE_URL=https://tu-proyecto.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJ...

# Privadas (solo servidor)
SUPABASE_SERVICE_ROLE_KEY=eyJ...
\`\`\`

## ⚠️ Importante

- **Nunca subas `.env.local` a Git**
- **La SERVICE_ROLE_KEY es secreta**
- **Reinicia el servidor después de cambiar variables**

## 🆘 Problemas Comunes

1. **Error de conexión**: Verifica las URLs
2. **Permisos**: Asegúrate de usar las claves correctas
3. **CORS**: Configura el dominio en Supabase si es necesario

## 📞 Soporte

Si tienes problemas, verifica:
1. Variables de entorno correctas
2. Proyecto de Supabase activo
3. Scripts ejecutados en orden
