<script setup>
import { ref, computed } from 'vue'
import axios from 'axios'
import PizZip from 'pizzip'
import Docxtemplater from 'docxtemplater'
import { saveAs } from 'file-saver'
import * as XLSX from 'xlsx'

// 生成UUID的函数
function generateUUID() {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
    const r = Math.random() * 16 | 0
    const v = c === 'x' ? r : (r & 0x3 | 0x8)
    return v.toString(16)
  })
}

// 使用示例：
// const uuid = generateUUID()
// console.log(uuid) // 输出类似：f47ac10b-58cc-4372-a567-0e02b2c3d479

const form = ref({
  plaintiff: '',
  defendant: '',
  reason: '',
  party: '',
  partyGender: '', // 新增 当事人性别
  partyNation: '', // 新增 当事人民族
  partyBirth: '',  // 新增 当事人出生年月日
  partyId: '',     // 新增 公民身份号码
  partyAddress: '',// 新增 住所
  lawyerName: '',
  lawyerGender: '',
  lawyerCompany: '',
  lawyerLicense: '',
  lawyerPhone: '',
  courtName: '',
  queryTime: ''
})



const genderOptions = [
  { label: '男', value: '男' },
  { label: '女', value: '女' }
]

// 银行卡表格数据
const bankTable = ref([
  { name: '', number: '', account: '' }
])

const factReason = ref('')

function addBankRow() {
  bankTable.value.push({ name: '', number: '', account: '' })
}

function removeBankRow(index) {
  bankTable.value.splice(index, 1)
}

// 上传文件，返回文件ID
async function uploadFile(file, user, token) {
  console.log(token)
  const uploadUrl = "/files/upload";
  const headers = {
    "Content-Type": "multipart/form-data",
    "Authorization": token
  };
  console.log(headers)
  const formData = new FormData();
  formData.append('file', file, file.name);
  formData.append('user', user);

  try {
    // 可选：显示“上传中...”提示
    const response = await axios.post(uploadUrl, formData,{ headers });
    if (response.status === 201) {
      // 上传成功
      // 返回文件ID
      return response.data.id;
    } else {
      // 上传失败
      console.error('文件上传失败，状态码:', response.status);
      return null;
    }
  } catch (e) {
    console.error('发生错误:', e);
    return null;
  }
}

// 运行工作流
async function runWorkflow(fileId, user, token, responseMode = "blocking") {
  const workflowUrl = "workflows/run";
  const headers = {
    "Content-Type": "application/json",
    "Authorization": token
  };
  const data = {
    inputs: {
      file: {
        transfer_method: "local_file",
        upload_file_id: fileId,
        type: "image"
      }
    },
    response_mode: responseMode,
    user: user
  };

  try {
    // 可选：显示“运行工作流...”提示
    const response = await axios.post(workflowUrl, data, { headers });
    if (response.status === 200) {
      // 工作流执行成功
      return response.data.data.outputs.text;
    } else {
      // 工作流执行失败
      console.error('工作流执行失败，状态码:', response.status);
      return { status: "error", message: `Failed to execute workflow, status code: ${response.status}` };
    }
  } catch (e) {
    console.error('发生错误:', e);
    return { status: "error", message: e.message };
  }
}

function extractJsonObject(response) {
  // 1. 取出 json 字符串
  let jsonStr = response;
  if (!jsonStr) return null;



  // 3. 去除多余的 ``` 和换行
  jsonStr = jsonStr.replace(/```json\\n|```/g, '').trim();
  jsonStr = jsonStr.replace(/json/g, '').trim();


  // 4. 解析为对象
  try {
    return JSON.parse(jsonStr);
  } catch (e) {
    console.error('JSON解析失败:', e, jsonStr);
    return null;
  }
}

// 添加状态变量
const isUploadingLawyer = ref(false)
const isUploadingParty = ref(false)
const isPolishing = ref(false)

// 律师信息上传
const lawyerFileInput = ref(null)
const uploadLawyerFile = () => {
  if (isUploadingLawyer.value) return
  lawyerFileInput.value.click()
}
const handleLawyerFileChange = async (e) => {
  const file = e.target.files[0]
  if (!file) return
  
  isUploadingLawyer.value = true
  try {
    const userId = generateUUID()
    // 先上传文件，拿到fileId
    const fileId = await uploadFile(file, userId, 'Bearer ' + localStorage.getItem('lawyerKey'))
    console.log('fileId:', fileId)
    if (fileId) {
      // 再调用工作流
      const response = await runWorkflow(fileId, userId, 'Bearer ' + localStorage.getItem('lawyerKey'))
      console.log('response:', response)
      const jsonObject = extractJsonObject(response)
      console.log('jsonObject:', jsonObject)
      // 你可以在这里处理response，比如自动填充表单
      form.value.lawyerName = jsonObject.lawyerName
      form.value.lawyerGender = jsonObject.lawyerGender
      form.value.lawyerCompany = jsonObject.lawyerCompany
      form.value.lawyerLicense = jsonObject.lawyerLicense
      form.value.lawyerPhone = jsonObject.lawyerPhone
    }
  } catch (error) {
    console.error('律师信息上传失败:', error)
  } finally {
    isUploadingLawyer.value = false
  }
}

// 当事人信息上传
const partyFileInput = ref(null)
const uploadPartyFile = () => {
  if (isUploadingParty.value) return
  partyFileInput.value.click()
}
const handlePartyFileChange = async (e) => {
  const file = e.target.files[0]
  if (!file) return
  
  isUploadingParty.value = true
  try {
    const userId = generateUUID()
    // 先上传文件，拿到fileId
    const fileId = await uploadFile(file, userId, 'Bearer ' + localStorage.getItem('partyKey') )
    if (fileId) {
      // 再调用工作流
      const response = await runWorkflow(fileId, userId, 'Bearer ' + localStorage.getItem('partyKey') )
      const jsonObject = extractJsonObject(response)
      // 自动填充当事人相关表单字段
      if (jsonObject) {
        form.value.party = jsonObject.party || ''
        form.value.partyGender = jsonObject.partyGender || ''
        form.value.partyNation = jsonObject.partyNation || ''
        form.value.partyBirth = jsonObject.partyBirth || ''
        form.value.partyId = jsonObject.partyId || ''
        form.value.partyAddress = jsonObject.partyAddress || ''
      }
    }
  } catch (error) {
    console.error('当事人信息上传失败:', error)
  } finally {
    isUploadingParty.value = false
  }
}

// AI辅助润色
async function polishFactReason() {
  if (isPolishing.value) return
  isPolishing.value = true
  const userId = generateUUID()
  const headers = {
    "Content-Type": "application/json",
    "Authorization": 'Bearer ' + localStorage.getItem('aiKey')
  };
  try {
    // 正确传递 factReason.value，避免循环引用
    const input = { reason: form.value.reason, text: factReason.value }
    const response = await axios.post('/completion-messages', { inputs: input, user: userId, response_mode: "blocking" }, { headers })
    // 假设后端返回 { polished: '润色后的文本' }
    if (response.data && response.data.answer) {
      factReason.value = response.data.answer
    }
  } catch (e) {
    console.error('AI润色失败:', e)
    // 可选：给用户提示润色失败
  } finally {
    isPolishing.value = false
  }
}

function formatDateToCN(dateStr) {
  if (!dateStr) return '';
  const [year, month, day] = dateStr.split('-');
  return `${year}年${month}月${day}日`;
}

/** 校验表单必填项 */
function validateForm() {
  const requiredFields = [
    { key: 'plaintiff', label: '原告姓名' },
    { key: 'defendant', label: '被告姓名' },
    { key: 'reason', label: '案由' },
    { key: 'party', label: '当事人姓名' },
    { key: 'partyGender', label: '当事人性别' },
    { key: 'partyNation', label: '当事人民族' },
    { key: 'partyBirth', label: '当事人出生年月日' },
    { key: 'partyId', label: '公民身份号码' },
    { key: 'partyAddress', label: '住所' },
    { key: 'lawyerName', label: '律师姓名' },
    { key: 'lawyerGender', label: '律师性别' },
    { key: 'lawyerCompany', label: '律师公司' },
    { key: 'lawyerLicense', label: '律师执业证号' },
    { key: 'lawyerPhone', label: '律师联系电话' },
    { key: 'courtName', label: '法院名称' },
    { key: 'queryTime', label: '查询时间' },
    { key: 'factReason', label: '事实和理由', isFactReason: true }
  ]
  for (const field of requiredFields) {
    if (field.isFactReason) {
      if (!factReason.value || !factReason.value.trim()) {
        alert(`请填写${field.label}`)
        return false
      }
    } else {
      if (!form.value[field.key] || !form.value[field.key].toString().trim()) {
        alert(`请填写${field.label}`)
        return false
      }
    }
  }
  // 校验银行卡表格至少有一行且每列都填写
  if (!bankTable.value.length || bankTable.value.some(row => !row.name.trim() || !row.number.trim() || !row.account.trim())) {
    alert('请完整填写至少一行当事人银行卡信息')
    return false
  }
  return true
}

const sleep = ms => new Promise(resolve => setTimeout(resolve, ms))

const submitForm = async (e) => {
  e.preventDefault()
  if (!validateForm()) return
  const n = bankTable.value.length
  for (let i = 0; i < n; i++) {
    await saveFile(i)
    if (i < n - 1) {
      await sleep(1000)
    }
  }
}

async function saveFile(index) {
  const {
    plaintiff,
    defendant,
    reason,
    party,
    partyGender,
    partyNation,
    partyBirth,
    partyId,
    partyAddress,
    lawyerName,
    lawyerGender,
    lawyerCompany,
    lawyerLicense,
    lawyerPhone,
    courtName,
    queryTime
  } = form.value
  // 拼接银行卡信息（每行name和number用空格）
  const bankTableStr = bankTable.value[index].name + ' ' + bankTable.value[index].number
  const submitData = {
    plaintiff,
    defendant,
    reason,
    party,
    partyGender,
    partyNation,
    partyBirth,
    partyId,
    partyAddress,
    lawyerName,
    lawyerGender,
    lawyerCompany,
    lawyerLicense,
    lawyerPhone,
    courtName,
    queryTime,
    bankTable: bankTable.value,
    factReason: factReason.value
  }
  console.log('提交数据:', submitData)

  // 读取public下的template.docx
  try {
    console.log('读取模板文件')
    const response = await fetch('/template.docx')
    const content = await response.arrayBuffer()
    console.log('模板文件已读取:', content)
    // 1. 加载模板
    const zip = new PizZip(content)
    const doc = new Docxtemplater(zip, { paragraphLoop: true, linebreaks: true })

    // 2. 构造替换映射
    // 你可以根据实际表单字段补充更多映射
    const replaceMap = {
      '原告姓名': submitData.plaintiff,
      '被告姓名': submitData.defendant,
      '案由': submitData.reason,
      '当事人姓名': submitData.party,
      '当事人性别': submitData.partyGender,
      '当事人民族': submitData.partyNation,
      '当事人出生年月日': submitData.partyBirth,
      '当事人身份证号码': submitData.partyId,
      '当事人住所': submitData.partyAddress,
      '律师姓名': submitData.lawyerName,
      '律师性别': submitData.lawyerGender,
      '律师公司': submitData.lawyerCompany,
      '律师执业证号': submitData.lawyerLicense,
      '律师联系电话': submitData.lawyerPhone,
      '法院名称': submitData.courtName,
      '查询时间': formatDateToCN(submitData.queryTime),
      '当事人银行卡号码': bankTableStr || '',
      '当事人银行卡所在账户': bankTable.value[index].account || '',
      '事实和理由': submitData.factReason
    }
    console.log('replaceMap:', replaceMap)

    // 3. 读取模板文本，批量替换
    doc.setData(replaceMap)
    try {
      doc.render()
    } catch (error) {
      console.error('渲染模板失败', error)
      return
    }
    const out = doc.getZip().generate({ type: 'blob' })
    saveAs(out, '律师调查令申请书' + bankTable.value[index].account + ' ' + queryTime+ '.docx')
  } catch (e) {
    console.error('读取模板文件失败:', e)
  }
}

// 银行卡信息上传
const bankFileInput = ref(null)
const uploadBankFile = () => {
  bankFileInput.value.click()
}
const handleBankFileChange = async (e) => {
  const file = e.target.files[0]
  if (!file) return
  
  try {
    const reader = new FileReader()
    reader.onload = function(e) {
      const data = new Uint8Array(e.target.result)
      
      // 使用 xlsx 库解析 Excel 文件
      const workbook = XLSX.read(data, { type: 'array' })
      const sheetName = workbook.SheetNames[0] // 获取第一个工作表
      const worksheet = workbook.Sheets[sheetName]
      
      // 将工作表转换为 JSON 数组
      const jsonData = XLSX.utils.sheet_to_json(worksheet, { header: 1 })
      
      // 清空现有数据
      bankTable.value = []
      
      // 跳过表头，从第二行开始读取
      for (let i = 1; i < jsonData.length; i++) {
        const row = jsonData[i]
        if (row && row.length >= 3) {
          bankTable.value.push({
            name: row[0] || '',
            number: row[1] || '',
            account: row[2] || ''
          })
        }
      }
      
      console.log('银行卡信息已导入:', bankTable.value)
    }
    reader.readAsArrayBuffer(file)
  } catch (error) {
    console.error('读取Excel文件失败:', error)
    alert('读取Excel文件失败，请确保文件格式正确')
  }
}

// 下载模板文件
const downloadTemplate = () => {
  const link = document.createElement('a')
  link.href = '/律师调查令信息填充模板.xlsx'
  link.download = '律师调查令信息填充模板.xlsx'
  document.body.appendChild(link)
  link.click()
  document.body.removeChild(link)
}

// 检查秘钥是否为空
const isLawyerKeyEmpty = computed(() => !localStorage.getItem('lawyerKey'))
const isPartyKeyEmpty = computed(() => !localStorage.getItem('partyKey'))
const isAiKeyEmpty = computed(() => !localStorage.getItem('aiKey'))

</script>

<template>
  <div class="form-center">
    <div class="form-card">
      <div class="form-title">案件信息填写</div>
      <form class="custom-form" @submit="submitForm">
        <!-- 原告信息 -->
        <div class="form-section">
          <div class="section-title-row">
            <div class="section-title">原告信息</div>
            <input ref="plaintiffFileInput" type="file" style="display:none" @change="handlePlaintiffFileChange" />
          </div>
          <div class="form-item">
            <label>原告姓名</label>
            <input v-model="form.plaintiff" type="text" placeholder="请输入原告姓名" />
          </div>
        </div>
        <!-- 被告信息 -->
        <div class="form-section">
          <div class="section-title-row">
            <div class="section-title">被告信息</div>
            <input ref="defendantFileInput" type="file" style="display:none" @change="handleDefendantFileChange" />
          </div>
          <div class="form-item">
            <label>被告姓名</label>
            <input v-model="form.defendant" type="text" placeholder="请输入被告姓名" />
          </div>
        </div>
        <!-- 当事人信息 -->
        <div class="form-section">
          <div class="section-title-row">
            <div class="section-title">当事人信息</div>
            <button type="button" class="upload-btn" :class="{ 'uploading': isUploadingParty, 'disabled': isPartyKeyEmpty }" :disabled="isUploadingParty || isPartyKeyEmpty" @click="uploadPartyFile">
              {{ isUploadingParty ? '正在录入' : '录入文件信息' }}
            </button>
            <input ref="partyFileInput" type="file" style="display:none" @change="handlePartyFileChange" />
          </div>
          <div class="form-item">
            <label>案由</label>
            <input v-model="form.reason" type="text" placeholder="请输入案由" />
          </div>
          <div class="form-item">
            <label>当事人姓名</label>
            <input v-model="form.party" type="text" placeholder="请输入当事人姓名" />
          </div>
          <div class="form-item">
            <label>当事人性别</label>
            <select v-model="form.partyGender">
              <option value="">请选择性别</option>
              <option value="男">男</option>
              <option value="女">女</option>
            </select>
          </div>
          <div class="form-item">
            <label>当事人民族</label>
            <input v-model="form.partyNation" type="text" placeholder="请输入当事人民族" />
          </div>
          <div class="form-item">
            <label>当事人出生年月日</label>
            <input v-model="form.partyBirth" type="text" placeholder="请输入当事人出生年月日" />
          </div>
          <div class="form-item">
            <label>公民身份号码</label>
            <input v-model="form.partyId" type="text" placeholder="请输入公民身份号码" />
          </div>
          <div class="form-item">
            <label>住所</label>
            <input v-model="form.partyAddress" type="text" placeholder="请输入住所" />
          </div>
          <!-- 银行卡信息表格 -->
          <div class="form-item">
            <div class="bank-info-header">
              <label style="margin-bottom:8px;">当事人银行卡信息</label>
              <div class="bank-buttons">
                <button type="button" class="download-btn" @click="downloadTemplate">下载模板</button>
                <button type="button" class="upload-btn" @click="uploadBankFile">录入银行卡信息</button>
                <input ref="bankFileInput" type="file" accept=".xlsx,.xls,.csv" style="display:none" @change="handleBankFileChange" />
              </div>
            </div>
            <table class="bank-table">
              <thead>
                <tr>
                  <th>当事人银行卡</th>
                  <th>当事人银行卡号码</th>
                  <th>当事人银行卡所在账户</th>
                  <th style="width:60px;"></th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="(row, idx) in bankTable" :key="idx">
                  <td><input v-model="row.name" type="text" placeholder="广发银行贷记卡2个：" /></td>
                  <td><input v-model="row.number" type="text" placeholder="5201521658888929，6250000000217917" /></td>
                  <td><input v-model="row.account" type="text" placeholder="广发银行股份有限公司广州分行" /></td>
                  <td>
                    <button type="button" @click="removeBankRow(idx)" v-if="bankTable.length > 1"
                      class="bank-del-btn">删除</button>
                  </td>
                </tr>
              </tbody>
            </table>
            <button type="button" class="bank-add-btn" @click="addBankRow">新增一行</button>
          </div>
        </div>
        <!-- 律师信息 -->
        <div class="form-section">
          <div class="section-title-row">
            <div class="section-title">律师信息</div>
            <button type="button" class="upload-btn" :class="{ 'uploading': isUploadingLawyer, 'disabled': isLawyerKeyEmpty }" :disabled="isUploadingLawyer || isLawyerKeyEmpty" @click="uploadLawyerFile">
              {{ isUploadingLawyer ? '正在录入' : '录入文件信息' }}
            </button>
            <input ref="lawyerFileInput" type="file" style="display:none" @change="handleLawyerFileChange" />
          </div>
          <div class="form-item">
            <label>律师姓名</label>
            <input v-model="form.lawyerName" type="text" placeholder="请输入律师姓名" />
          </div>
          <div class="form-item">
            <label>律师性别</label>
            <select v-model="form.lawyerGender">
              <option value="">请选择性别</option>
              <option v-for="item in genderOptions" :key="item.value" :value="item.value">{{ item.label }}</option>
            </select>
          </div>
          <div class="form-item">
            <label>律师公司</label>
            <input v-model="form.lawyerCompany" type="text" placeholder="请输入律师公司" />
          </div>
          <div class="form-item">
            <label>律师执业证号</label>
            <input v-model="form.lawyerLicense" type="text" placeholder="请输入律师执业证号" />
          </div>
          <div class="form-item">
            <label>律师联系电话</label>
            <input v-model="form.lawyerPhone" type="text" placeholder="请输入律师联系电话" />
          </div>
        </div>
        <!-- 统一信息 -->
        <div class="form-item fact-reason-row">
          <label>事实和理由</label>
          <div class="fact-reason-flex">
            <textarea v-model="factReason" class="fact-reason-textarea" placeholder="请输入事实和理由"></textarea>
            <button type="button" class="ai-polish-btn" :class="{ 'uploading': isPolishing, 'disabled': isAiKeyEmpty }" :disabled="isPolishing || isAiKeyEmpty" @click="polishFactReason">
              {{ isPolishing ? '正在生成' : 'AI辅助润色' }}
            </button>
          </div>
        </div>
        <div class="form-item">
          <label>法院名称</label>
          <input v-model="form.courtName" type="text" placeholder="请输入法院名称" />
        </div>
        <div class="form-item">
          <label>查询时间</label>
          <input v-model="form.queryTime" type="date" />
        </div>
        <div class="form-item">
          <button type="submit" class="submit-btn">提交</button>
        </div>
      </form>
    </div>
  </div>
</template>

<style scoped>
.form-center {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #f7f8fa;
}

.form-card {
  width: 100%;
  max-width: 700px;
  border-radius: 10px;
  padding: 28px 18px 10px 18px;
  box-shadow: 0 2px 8px 0 rgba(0, 0, 0, 0.04);
  border: 1px solid #f0f0f0;
  background: #fff;
}

.form-title {
  font-size: 20px;
  font-weight: 500;
  text-align: center;
  margin-bottom: 18px;
  color: #222;
  letter-spacing: 1px;
}

.custom-form {
  margin-top: 0;
}

.form-section {
  margin-bottom: 18px;
  padding-bottom: 10px;
  border-bottom: 1px solid #f0f0f0;
}

.form-section:last-of-type {
  border-bottom: none;
}

.section-title-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 10px;
}

.upload-btn {
  background: #67c23a;
  color: #fff;
  border: none;
  border-radius: 4px;
  padding: 4px 12px;
  font-size: 14px;
  cursor: pointer;
  margin-left: 10px;
  transition: background 0.2s;
}

.upload-btn:hover {
  background: #4caf50;
}

.section-title {
  font-size: 16px;
  font-weight: 600;
  color: #409eff;
  margin-bottom: 10px;
  margin-top: 2px;
}

.form-item {
  display: flex;
  flex-direction: column;
  margin-bottom: 14px;
}

.form-item label {
  margin-bottom: 6px;
  color: #555;
  font-size: 15px;
}

.form-item input,
.form-item select {
  height: 36px;
  padding: 0 10px;
  border: 1px solid #dcdfe6;
  border-radius: 5px;
  font-size: 15px;
  background: #fafbfc;
  transition: border 0.2s;
}

.form-item input:focus,
.form-item select:focus {
  border: 1.5px solid #409eff;
  outline: none;
  background: #fff;
}

.bank-table {
  width: 100%;
  border-collapse: collapse;
  margin-bottom: 8px;
}

.bank-table th,
.bank-table td {
  border: 1px solid #e0e0e0;
  padding: 6px 4px;
  text-align: left;
}

.bank-table th {
  background: #f5f7fa;
  font-weight: 500;
}

.bank-add-btn {
  background: #409eff;
  color: #fff;
  border: none;
  border-radius: 4px;
  padding: 4px 12px;
  font-size: 14px;
  cursor: pointer;
  margin-top: 4px;
  transition: background 0.2s;
}

.bank-add-btn:hover {
  background: #337ecc;
}

.bank-del-btn {
  background: #f56c6c;
  color: #fff;
  border: none;
  border-radius: 4px;
  padding: 2px 8px;
  font-size: 13px;
  cursor: pointer;
  transition: background 0.2s;
}

.bank-del-btn:hover {
  background: #c0392b;
}

.submit-btn {
  width: 100%;
  height: 38px;
  background: #409eff;
  color: #fff;
  border: none;
  border-radius: 5px;
  font-size: 16px;
  font-weight: 500;
  letter-spacing: 1px;
  cursor: pointer;
  transition: background 0.2s;
}

.submit-btn:hover {
  background: #337ecc;
}

.fact-reason-flex {
  display: flex;
  align-items: flex-start;
  width: 100%;
}

.fact-reason-textarea {
  min-height: 100px;
  resize: vertical;
  border: 1px solid #dcdfe6;
  border-radius: 5px;
  font-size: 15px;
  padding: 10px;
  background: #fafbfc;
  transition: border 0.2s;
  flex: 3 1 0%;
  /* 让输入框更宽 */
  width: 100%;
  max-width: 100%;
}

.fact-reason-row {
  align-items: flex-start;
}

.ai-polish-btn {
  margin-left: 12px;
  height: 38px;
  background: #67c23a;
  color: #fff;
  border: none;
  border-radius: 5px;
  font-size: 15px;
  font-weight: 500;
  letter-spacing: 1px;
  cursor: pointer;
  padding: 0 18px;
  transition: background 0.2s;
  white-space: nowrap;
}

.ai-polish-btn:hover {
  background: #4caf50;
}

.bank-info-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 8px;
}
.bank-buttons {
  display: flex;
  gap: 8px;
  align-items: center;
}
.download-btn {
  background: #409eff;
  color: #fff;
  border: none;
  border-radius: 4px;
  padding: 4px 12px;
  font-size: 14px;
  cursor: pointer;
  transition: background 0.2s;
}
.download-btn:hover {
  background: #337ecc;
}
.upload-btn.disabled,
.ai-polish-btn.disabled {
  background: #c0c4cc !important;
  cursor: not-allowed;
  opacity: 0.6;
}
.upload-btn.uploading {
  background: #c0c4cc;
}
.ai-polish-btn.uploading {
  background: #c0c4cc;
}
</style>
