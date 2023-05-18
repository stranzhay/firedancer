use std::{collections::HashMap, process::{Command, Stdio}};

use clap::{arg, Args};

use crate::*;

#[derive(Debug, Args)]
pub(crate) struct Run {
    #[arg(long)]
    clean: bool,

    #[arg(long)]
    configure: bool,

    #[arg(long)]
    debug: bool,

    #[arg(long)]
    monitor: bool,
}

impl Run {
    pub(crate) fn needs_root(&self) -> bool {
        self.clean || self.configure || self.debug || self.monitor
    }
}

pub(crate) fn monitor(config: &Config) {
    let vars_file = std::fs::read_to_string(&format!(
        "{}/{}.cfg",
        config.scratch_directory, config.name
    ))
    .unwrap();
    let vars: HashMap<&str, &str> = HashMap::from_iter(
        vars_file
            .trim()
            .lines()
            .skip(2)
            .map(|x| x.split_once('=').unwrap()),
    );

    let mut monitor =
        Command::new(format!("{}/fd_frank_mon.bin", config.binary_dir.display()))
            .args([
                "--pod",
                vars["POD"],
                "--cfg",
                &config.name,
                "--log-app",
                &config.name,
                "--log-thread",
                "mon",
                "--duration",
                &"31536000000000000".to_string(),
            ])
            .spawn()
            .unwrap();

    let status = monitor.wait().unwrap();
    assert!(status.success());
}

pub(crate) fn run(args: Run, config: &mut Config) {
    if args.configure {
        if args.clean {
            super::configure(super::configure::ConfigureCommand::Fini, config);
        }
        super::configure(super::configure::ConfigureCommand::Init, config);
    }

    let vars_file = std::fs::read_to_string(&format!(
        "{}/{}.cfg",
        config.scratch_directory, config.name
    ))
    .unwrap();
    let vars: HashMap<&str, &str> = HashMap::from_iter(
        vars_file
            .trim()
            .lines()
            .skip(2)
            .map(|x| x.split_once('=').unwrap()),
    );

    let run_binary = format!("{}/fd_frank_run.bin", config.binary_dir.display());

    let mut run_args = vec![];
    if args.debug {
        run_args.extend(["gdb", "--args"]);
    }
    run_args.extend([
        "--pod",
        &vars["POD"],
        "--cfg",
        &config.name,
        "--log-app",
        &config.name,
        "--log-thread",
        "main",
        "--tile-cpus",
        &config.affinity,
    ]);

    if args.debug || !args.monitor {
        let mut child = Command::new(&run_binary).args(run_args).spawn().unwrap();

        let status = child.wait().unwrap();
        assert!(status.success());
    } else {
        let mut child = Command::new(&run_binary)
            .args(run_args)
            .stdout(Stdio::null())
            .stderr(Stdio::null())
            .spawn()
            .unwrap();

        let mut monitor =
            Command::new(format!("{}/fd_frank_mon.bin", config.binary_dir.display()))
                .args([
                    "--pod",
                    &vars["POD"],
                    "--cfg",
                    &config.name,
                    "--log-app",
                    &config.name,
                    "--log-thread",
                    "mon",
                    "--duration",
                    &"31536000000000000".to_string(),
                ])
                .spawn()
                .unwrap();

        let status = monitor.wait().unwrap();
        assert!(status.success());

        let status = child.wait().unwrap();
        assert!(status.success());
    }
}