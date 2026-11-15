use crate::config::{Config, Shared};
use crate::errors::*;
use std::future;
use std::sync::Arc;
use tokio::task::JoinSet;

// Handle shutdown signals so we can run this as pid1
pub async fn sigterm() {
    let mut set = JoinSet::new();

    // On ctrl-c, shutdown
    set.spawn(async {
        let _ = tokio::signal::ctrl_c().await;
    });

    #[cfg(unix)]
    {
        // On SIGTERM, shutdown
        use tokio::signal::unix;
        if let Ok(mut signal) = unix::signal(unix::SignalKind::terminate()) {
            set.spawn(async move {
                signal.recv().await;
            });
        }
    }

    set.join_next().await;
}

pub async fn sighup(shared: Arc<Shared>) {
    #[cfg(unix)]
    {
        use tokio::signal::unix;

        if let Ok(mut signals) = unix::signal(unix::SignalKind::hangup()) {
            while signals.recv().await.is_some() {
                info!("Received SIGHUP, reloading configuration");

                let path = shared.config_path();
                match Config::load(path).await {
                    Ok(config) => {
                        shared.replace_config(config);
                        info!("Configuration reloaded");
                    }
                    Err(err) => {
                        error!("Failed to reload configuration from {path:?}: {err:#}");
                    }
                }
            }
        }
    }

    // Reload signals not supported, wait indefinitely
    future::pending().await
}
