<script setup>
import { ref } from 'vue'

const keys = ref({
  lawyerKey: '',
  partyKey: '',
  aiKey: ''
})

const saveKeys = () => {
  // 保存到localStorage
  localStorage.setItem('lawyerKey', keys.value.lawyerKey)
  localStorage.setItem('partyKey', keys.value.partyKey)
  localStorage.setItem('aiKey', keys.value.aiKey)
  alert('秘钥已保存')
}

const loadKeys = () => {
  // 从localStorage加载
  keys.value.lawyerKey = localStorage.getItem('lawyerKey') || ''
  keys.value.partyKey = localStorage.getItem('partyKey') || ''
  keys.value.aiKey = localStorage.getItem('aiKey') || ''
}

// 页面加载时自动加载秘钥
loadKeys()
</script>

<template>
  <div class="about">
    <div class="keys-container">
      <h1>秘钥配置</h1>
      <div class="key-form">
        <div class="key-item">
          <label>律师信息秘钥</label>
          <input v-model="keys.lawyerKey" type="password" placeholder="请输入律师信息API秘钥" />
        </div>
        <div class="key-item">
          <label>当事人信息秘钥</label>
          <input v-model="keys.partyKey" type="password" placeholder="请输入当事人信息API秘钥" />
        </div>
        <div class="key-item">
          <label>AI润色秘钥</label>
          <input v-model="keys.aiKey" type="password" placeholder="请输入AI润色API秘钥" />
        </div>
        <button @click="saveKeys" class="save-btn">保存秘钥</button>
      </div>
    </div>
  </div>
</template>

<style scoped>
.about {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #f7f8fa;
}

.keys-container {
  background: white;
  padding: 40px;
  border-radius: 10px;
  box-shadow: 0 2px 8px 0 rgba(0,0,0,0.04);
  border: 1px solid #f0f0f0;
  width: 100%;
  max-width: 500px;
}

.keys-container h1 {
  text-align: center;
  margin-bottom: 30px;
  color: #333;
  font-size: 24px;
}

.key-form {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.key-item {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.key-item label {
  font-weight: 500;
  color: #555;
  font-size: 14px;
}

.key-item input {
  padding: 12px;
  border: 1px solid #dcdfe6;
  border-radius: 5px;
  font-size: 14px;
  background: #fafbfc;
  transition: border 0.2s;
}

.key-item input:focus {
  border: 1.5px solid #409eff;
  outline: none;
  background: #fff;
}

.save-btn {
  background: #409eff;
  color: #fff;
  border: none;
  border-radius: 5px;
  padding: 12px;
  font-size: 16px;
  font-weight: 500;
  cursor: pointer;
  transition: background 0.2s;
  margin-top: 10px;
}

.save-btn:hover {
  background: #337ecc;
}
</style>
