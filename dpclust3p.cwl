cwlVersion: v1.0
class: CommandLineTool
label: dpclust3p
baseCommand: [ Rscript, /opt/dpclust3p/DPClust_prepareInputs_TCGA.R ]
requirements:
  - class: DockerRequirement
    dockerPull: opengenomics/dpclust3p:v3.0

inputs:
  vcfpath:
    type: Directory
    inputBinding:
      position: 1
  cnapath:
    type: Directory
    inputBinding:
      position: 2
  sampleid:
    type: string
    inputBinding:
      position: 3
  purity:
    type: float
    inputBinding:
      position: 4
  ploidy:
    type: float
    inputBinding:
      position: 5
  gender:
    type: string
    inputBinding:
      position: 6
  workdir:
    type: string
    default: ./
    inputBinding:
      position: 7

outputs:
  dpout:
    type: File
    outputBinding:
      glob: $(inputs.sampleid)_dpInput.txt
