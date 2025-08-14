module.exports = {
  apps: [{
    name: 'nextjs-template',
    script: 'npm',
    args: 'run start',
    cwd: '/home/buarac/app/nextjs_template/scripts/myapp',
    instances: 1,
    exec_mode: 'fork',
    
    // Variables d'environnement  
    env: {
      NODE_ENV: 'production',
      PORT: 3000  // ← Modifier ce port selon tes besoins
    },
    
    // Fichier d'environnement
    env_file: '.env.production',
    
    // Logs
    log_file: 'logs/app.log',
    out_file: 'logs/out.log',
    error_file: 'logs/error.log',
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
    
    // Redémarrage automatique
    watch: false,
    max_restarts: 10,
    min_uptime: '10s',
    max_memory_restart: '500M',
    
    // Configuration avancée
    kill_timeout: 5000,
    wait_ready: true,
    listen_timeout: 10000,
    
    // Monitoring
    monitoring: true
  }]
}