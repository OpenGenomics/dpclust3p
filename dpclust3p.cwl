cwlVersion: v1.0
class: CommandLineTool
label: dpclust3p
baseCommand: [ Rscript, /opt/dpclust3p/DPClust_prepareInputs_TCGA.R ]
requirements:
  - class: DockerRequirement
    dockerPull: opengenomics/dpclust3p:v2.0

inputs:
  vcfpath:
    type: string
    inputBinding:
      position: 1
  cnapath:
    type: string
    inputBinding:
      position: 2
  sampleid:
    type: string
    inputBinding:
      position: 3
  workdir:
    type: string
    default: ./
    inputBinding:
      position: 4

outputs:
  dpout:
    type: File
    outputBinding:
      glob: $(inputs.sampleid)_allDirichletProcessInfo.txt
