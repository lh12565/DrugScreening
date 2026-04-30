# Drug Screening Pipeline: AutoDock Vina + Molecular Dynamics

This repository provides an integrated computational workflow for structure-based drug screening. It combines **AutoDock Vina** for high-throughput virtual screening and **Molecular Dynamics (MD)** simulations for refinement and binding stability assessment.

The pipeline is designed to:
- **Docking**: High-throughput virtual screening using AutoDock Vina to predict binding affinities and poses of small molecules against a target protein.
- **MD**: Molecular Dynamics simulations for refining docking poses, assessing complex stability, and analyzing binding interactions under physiological conditions. The MD module uses the CHARMM36 force field (July 2022) and includes custom scripts for modifying MD-related files and processing small molecule ligands.

## Repository Structure
```
DrugScreen/
├── Docking/
│ └── AutoDock Vina.sh # Main script for running AutoDock Vina docking
│
├── MD/
│ ├── charmm36-jul2022.ff/ # CHARMM36 force field files (July 2022 release)
│ ├── mdp/ # GROMACS .mdp parameter files (minimization, equilibration, production)
│ ├── script/ # In-house scripts for modifying MD files and processing small molecules
│ └── MD.sh # Main script to run the entire MD pipeline
```

## Requirements

### AutoDock Vina
- [AutoDock Vina](https://github.com/ccsb-scripps/AutoDock-Vina)   (v1.2.5)
- [Meeko](https://github.com/forlilab/Meeko)  (for preparing ligand PDBQT files)  (v0.4.0)
- [MGLTools/AutoDockTools](https://ccsb.scripps.edu/mgltools/) (for preparing receptor PDBQT files)  (v1.5.7)
- [RDKit](https://github.com/rdkit/rdkit) (free) 或 [Schrödinger](https://www.schrodinger.com/release-download/) (commercial)

### Molecular Dynamics
- [GROMACS](https://manual.gromacs.org/current/download.html) (v2022.3 or later)
- [gmx_MMPBSA](https://valdes-tresanco-ms.github.io/gmx_MMPBSA/dev/installation/)  (v1.5.7 based on MMPBSA version 16.0 and AmberTools 20)
- [Avogadro](https://avogadro.cc/install/index.html)  (v1.2.0)


