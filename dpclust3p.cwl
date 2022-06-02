cwlVersion: v1.0
class: CommandLineTool
label: dpclust3p
baseCommand: [ Rscript, /opt/dpclust3p/DPClust_prepareInputs_TCGA_BB.R ]
requirements:
  - class: DockerRequirement
    dockerPull: quay.io/ohsugdanpipelines/dpclust

inputs:
  vcfpath:
    type: File
    inputBinding:
      position: 1
  cnapath:
    type: File
    inputBinding:
      position: 2
  sampleid:
    type: string
    inputBinding:
      position: 3
  rho_psi:
    type: File
    inputBinding:
      position: 4
  gender:
    type: string
    inputBinding:
      position: 5
  workdir:
    type: string
    default: ./
    inputBinding:
      position: 6

outputs:
  dpout:
    type: Directory
    outputBinding:
      glob: ./$(inputs.sampleid)
  dpfile:
    type: File
    outputBinding:
      glob: ./$(inputs.sampleid)/$(inputs.sampleid)_dpInput.txt
