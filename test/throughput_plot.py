#!/usr/bin/env python3
import ROOT
import glob
import json

ROOT.gROOT.SetBatch()

#'commit hash: 8189a9f0f08'

valuesCPUCPU = [
  [ 1, 185.5, 0.4],
  [ 4, 184.3, 0.7],
  [ 8, 187.6, 1.2],
  [16, 184.2, 0.6],
  [32, 182.7, 1.0],
  [64, 181.9, 0.5],
]

valuesGPUCPU = [
  [ 1, 384.9, 0.7],
  [ 4, 375.0, 0.8],
  [ 8, 379.4, 0.1],
  [16, 371.1, 0.6],
  [32, 372.5, 0.9],
  [64, 357.1, 2.5],
]

valuesGPUGPU = [
  [ 1, 372.4, 1.9],
  [ 4, 440.8, 0.6],
  [ 8, 513.4, 1.3],
  [16, 416.5, 6.1],
  [32, 339.0, 5.9],
  [64, 227.0, 1.7],
]

values = [
  valuesCPUCPU,
  valuesGPUCPU,
  valuesGPUGPU,
]

colors = [
  ROOT.kRed,
  ROOT.kBlack,
  ROOT.kBlue,
]
graphs = [None]*len(colors)
for g_idx in range(len(graphs)):
  graphs[g_idx] = ROOT.TGraphAsymmErrors()
  graphs[g_idx].SetMarkerSize(1.70)
  graphs[g_idx].SetMarkerStyle(20)
  graphs[g_idx].SetMarkerColor(colors[g_idx])
  graphs[g_idx].SetLineColor(colors[g_idx])
  graphs[g_idx].SetName('g'+str(g_idx))
  for v_idx in range(len(values[g_idx])):
    graphs[g_idx].SetPoint(v_idx, values[g_idx][v_idx][0], values[g_idx][v_idx][1])
    graphs[g_idx].SetPointEYhigh(v_idx, values[g_idx][v_idx][2])
    graphs[g_idx].SetPointEYlow (v_idx, values[g_idx][v_idx][2])

param = [
  1200,900,
  0.12,0.11,0.02,0.02,
  1.00,1.15,
  0.045,0.045,
]
canvas = ROOT.TCanvas('v1','v1',param[0],param[1])
canvas.SetLeftMargin(param[2])
canvas.SetBottomMargin(param[3])
canvas.SetRightMargin(param[4])
canvas.SetTopMargin(param[5])
canvas.cd()
h0 = canvas.DrawFrame(0, 120, 65, 700)
graphs[0].Draw('p')
graphs[1].Draw('p')
graphs[2].Draw('p')
#vexp = ROOT.TF1('f1','1.0+x/8.*560./1035.',0,11)
#vexp.SetLineColor(1)
#vexp.SetLineStyle(1)
#vexp.SetLineWidth(1)
#vexp.Draw('l,same')
h0.SetStats(0)
h0.SetTitle(';Threads(=Streams);Throughput [events / sec];')
h0.GetXaxis().SetTitleOffset(param[6])
h0.GetYaxis().SetTitleOffset(param[7])
h0.GetXaxis().SetTitleSize(param[8])
h0.GetYaxis().SetTitleSize(param[9])
#leg1 = ROOT.TLegend(0.17, 0.91, 0.60, 0.96)
#leg1.SetNColumns(1)
#leg1.SetBorderSize(0)
#leg1.SetTextFont(42)
#leg1.SetTextSize(0.040)
#leg1.SetEntrySeparation(0.4)
#leg1.AddEntry(vexp,'V_{ofs} + I_{in} / 8 #upoint R_{ext} / 1035','l')
#leg1.Draw('same')
leg2 = ROOT.TLegend(0.17, 0.75, 0.55, 0.96)
leg2.SetNColumns(1)
leg2.SetBorderSize(0)
leg2.SetTextFont(42)
leg2.SetTextSize(0.035)
#leg2.SetEntrySeparation(0.4)
leg2.AddEntry(graphs[0],'A (calo=CPU, pf=CPU)','p')
leg2.AddEntry(graphs[1],'B (calo=GPU, pf=CPU)','p')
leg2.AddEntry(graphs[2],'C (calo=GPU, pf=GPU)','p')
leg2.Draw('same')

topLabel1 = ROOT.TPaveText(0.60, 0.90, 0.95, 0.96, 'NDC')
topLabel1.SetFillColor(0)
topLabel1.SetFillStyle(1001)
topLabel1.SetTextColor(ROOT.kBlack)
topLabel1.SetTextAlign(12)
topLabel1.SetTextFont(42)
topLabel1.SetTextSize(0.035)
topLabel1.SetBorderSize(0)
topLabel1.AddText('2022 Run-3 data (run 357329)')
topLabel1.Draw('same')

topLabel2 = ROOT.TPaveText(0.60, 0.84, 0.95, 0.90, 'NDC')
topLabel2.SetFillColor(0)
topLabel2.SetFillStyle(1001)
topLabel2.SetTextColor(ROOT.kBlack)
topLabel2.SetTextAlign(12)
topLabel2.SetTextFont(42)
topLabel2.SetTextSize(0.035)
topLabel2.SetBorderSize(0)
topLabel2.AddText('700 events per estimate')
topLabel2.Draw('same')

topLabel3 = ROOT.TPaveText(0.60, 0.78, 0.95, 0.84, 'NDC')
topLabel3.SetFillColor(0)
topLabel3.SetFillStyle(1001)
topLabel3.SetTextColor(ROOT.kBlack)
topLabel3.SetTextAlign(12)
topLabel3.SetTextFont(42)
topLabel3.SetTextSize(0.035)
topLabel3.SetBorderSize(0)
topLabel3.AddText('# jobs = 64 / # threads')
topLabel3.Draw('same')

canvas.SetGrid(1,1)
canvas.SetLogz(0)
canvas.SaveAs('throughput_pfOnGPU_8189a9f0f08.pdf')
canvas.SaveAs('throughput_pfOnGPU_8189a9f0f08.png')
