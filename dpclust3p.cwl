cwlVersion: v1.0
class: CommandLineTool
label: dpclust3p
baseCommand: [ Rscript, /opt/dpclust3p/DPClust_prepareInputs_TCGA.R ]
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
    type: Directory
    outputBinding:
      glob: ./$(inputs.sampleid)
  dpfile:
    type: File
    outputBinding:
      glob: ./$(inputs.sampleid)/$(inputs.sampleid)_dpInput.txt
