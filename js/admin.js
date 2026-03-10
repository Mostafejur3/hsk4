// Admin Panel State
let adminState = {
    connected: false,
    supabaseClient: null,
    currentFile: null,
    parsedData: null
};

// Tab Switching
function switchTab(tabName) {
    // Update tab buttons
    document.querySelectorAll('.tab').forEach(tab => {
        tab.classList.remove('active');
    });
    event.target.classList.add('active');
    
    // Update tab content
    document.querySelectorAll('.tab-content').forEach(content => {
        content.classList.remove('active');
    });
    document.getElementById(`tab-${tabName}`).classList.add('active');
}

// Supabase Connection
async function connectSupabase() {
    const url = document.getElementById('supabaseUrl').value;
    const key = document.getElementById('supabaseKey').value;
    
    if (!url || !key) {
        alert('Please enter both URL and API key');
        return;
    }
    
    try {
        // Initialize Supabase client
        adminState.supabaseClient = supabase.createClient(url, key);
        
        // Test connection
        const { data, error } = await adminState.supabaseClient
            .from('dialogues')
            .select('count')
            .limit(1);
            
        if (error) throw error;
        
        adminState.connected = true;
        updateConnectionStatus(true);
        alert('Successfully connected to Supabase!');
        
        // Preview default table
        previewTableData();
        
    } catch (error) {
        console.error('Connection error:', error);
        adminState.connected = false;
        updateConnectionStatus(false);
        alert('Connection failed: ' + error.message);
    }
}

function updateConnectionStatus(connected) {
    const statusEl = document.getElementById('connectionStatus');
    if (connected) {
        statusEl.className = 'connection-status status-connected';
        statusEl.innerHTML = '<i class="fas fa-circle"></i> Connected';
    } else {
        statusEl.className = 'connection-status status-disconnected';
        statusEl.innerHTML = '<i class="fas fa-circle"></i> Not Connected';
    }
}

async function testConnection() {
    if (!adminState.connected || !adminState.supabaseClient) {
        alert('Please connect to Supabase first');
        return;
    }
    
    try {
        const { data, error } = await adminState.supabaseClient
            .from('dialogues')
            .select('*')
            .limit(1);
            
        if (error) throw error;
        
        alert('Connection test successful!');
    } catch (error) {
        alert('Connection test failed: ' + error.message);
    }
}

async function previewTableData() {
    if (!adminState.connected || !adminState.supabaseClient) {
        document.getElementById('dataPreview').innerHTML = '<p>Please connect to database first...</p>';
        return;
    }
    
    const table = document.getElementById('previewTable').value;
    const previewEl = document.getElementById('dataPreview');
    
    try {
        const { data, error } = await adminState.supabaseClient
            .from(table)
            .select('*')
            .limit(5);
            
        if (error) throw error;
        
        if (data && data.length > 0) {
            previewEl.innerHTML = '<pre>' + JSON.stringify(data, null, 2) + '</pre>';
        } else {
            previewEl.innerHTML = '<p>No data found in table: ' + table + '</p>';
        }
    } catch (error) {
        previewEl.innerHTML = '<p>Error loading data: ' + error.message + '</p>';
    }
}

function refreshPreview() {
    previewTableData();
}

function clearPreview() {
    document.getElementById('dataPreview').innerHTML = '<p>Preview cleared. Connect to database to preview data...</p>';
}

// File Upload Handling
function handleFileSelect(event) {
    const file = event.target.files[0];
    if (!file) return;
    
    adminState.currentFile = file;
    
    // Update file info
    document.getElementById('fileName').textContent = file.name;
    document.getElementById('fileSize').textContent = (file.size / 1024).toFixed(2) + ' KB';
    document.getElementById('fileType').textContent = file.type || 'text/plain';
    
    document.getElementById('fileInfo').classList.add('active');
}

function parseAndPreview() {
    if (!adminState.currentFile) {
        alert('Please select a file first');
        return;
    }
    
    const reader = new FileReader();
    reader.onload = function(e) {
        const content = e.target.result;
        const uploadType = document.getElementById('uploadType').value;
        
        // Parse based on file type and upload type
        adminState.parsedData = parseFileContent(content, uploadType);
        
        // Display preview
        const previewEl = document.getElementById('parsedPreview');
        previewEl.innerHTML = '<pre>' + JSON.stringify(adminState.parsedData, null, 2) + '</pre>';
    };
    
    reader.readAsText(adminState.currentFile);
}

function parseFileContent(content, type) {
    const lines = content.split('\n').filter(line => line.trim() !== '');
    const parsed = [];
    
    if (type === 'dialogues') {
        // Parse dialogue format
        let currentItem = {};
        for (let line of lines) {
            if (line.startsWith('Chinese:')) {
                if (currentItem.chinese) {
                    parsed.push(currentItem);
                    currentItem = {};
                }
                currentItem.chinese = line.replace('Chinese:', '').trim();
            } else if (line.startsWith('Pinyin:')) {
                currentItem.pinyin = line.replace('Pinyin:', '').trim();
            } else if (line.startsWith('English:')) {
                currentItem.english = line.replace('English:', '').trim();
            }
        }
        if (currentItem.chinese) {
            parsed.push(currentItem);
        }
    } else if (type === 'fill_blanks') {
        // Parse fill in blanks format
        for (let i = 0; i < lines.length; i += 6) {
            if (lines[i]) {
                parsed.push({
                    sentence: lines[i].replace('Sentence:', '').trim(),
                    options: lines[i+1] ? lines[i+1].replace('Options:', '').trim().split(',') : [],
                    correctAnswer: lines[i+2] ? parseInt(lines[i+2].replace('Correct:', '').trim()) : 0,
                    explanation: lines[i+3] ? lines[i+3].replace('Explanation:', '').trim() : ''
                });
            }
        }
    }
    
    return parsed;
}

async function uploadToDatabase() {
    if (!adminState.connected || !adminState.supabaseClient) {
        alert('Please connect to Supabase first');
        return;
    }
    
    if (!adminState.parsedData || adminState.parsedData.length === 0) {
        alert('No data to upload. Please parse a file first.');
        return;
    }
    
    const table = document.getElementById('uploadType').value;
    
    try {
        const { data, error } = await adminState.supabaseClient
            .from(table)
            .insert(adminState.parsedData);
            
        if (error) throw error;
        
        alert(`Successfully uploaded ${adminState.parsedData.length} items!`);
        clearParsedPreview();
        
        // Refresh preview
        previewTableData();
        
    } catch (error) {
        alert('Upload failed: ' + error.message);
    }
}

function clearParsedPreview() {
    adminState.parsedData = null;
    document.getElementById('parsedPreview').innerHTML = '<p>Upload a file to preview parsed data...</p>';
    document.getElementById('fileInfo').classList.remove('active');
    adminState.currentFile = null;
}

// Content Management
async function loadContentForManagement() {
    if (!adminState.connected || !adminState.supabaseClient) {
        alert('Please connect to Supabase first');
        return;
    }
    
    const type = document.getElementById('manageType').value;
    const contentList = document.getElementById('contentList');
    
    try {
        const { data, error } = await adminState.supabaseClient
            .from(type)
            .select('*')
            .limit(20);
            
        if (error) throw error;
        
        if (data && data.length > 0) {
            let html = '<div style="display: grid; gap: 1rem;">';
            data.forEach(item => {
                html += `
                    <div style="padding: 1rem; background: #f8f9fa; border-radius: 8px;">
                        <div style="display: flex; justify-content: space-between; margin-bottom: 0.5rem;">
                            <strong>ID: ${item.id}</strong>
                            <div>
                                <button class="action-btn edit-btn" onclick="editItem(${item.id})">
                                    <i class="fas fa-edit"></i>
                                </button>
                                <button class="action-btn delete-btn" onclick="deleteItem(${item.id}, '${type}')">
                                    <i class="fas fa-trash"></i>
                                </button>
                            </div>
                        </div>
                        <div>${item.chinese_text || item.question || item.sentence || JSON.stringify(item).substring(0, 100)}...</div>
                    </div>
                `;
            });
            html += '</div>';
            contentList.innerHTML = html;
        } else {
            contentList.innerHTML = '<p>No items found</p>';
        }
    } catch (error) {
        contentList.innerHTML = '<p>Error loading content: ' + error.message + '</p>';
    }
}

function showAddNewForm() {
    alert('Add new form would open here');
}

function editItem(id) {
    alert('Edit item: ' + id);
}

async function deleteItem(id, type) {
    if (!confirm('Are you sure you want to delete this item?')) {
        return;
    }
    
    try {
        const { error } = await adminState.supabaseClient
            .from(type)
            .delete()
            .match({ id });
            
        if (error) throw error;
        
        alert('Item deleted successfully');
        loadContentForManagement();
        
    } catch (error) {
        alert('Delete failed: ' + error.message);
    }
}

// User Management
function viewUserDetails(username) {
    alert('Viewing details for: ' + username);
}

function resetUserProgress(username) {
    if (confirm(`Reset progress for ${username}?`)) {
        alert('Progress reset for: ' + username);
    }
}

// Initialize admin panel
document.addEventListener('DOMContentLoaded', () => {
    // Check for existing connection in localStorage
    const savedUrl = localStorage.getItem('supabase_url');
    const savedKey = localStorage.getItem('supabase_key');
    
    if (savedUrl && savedKey) {
        document.getElementById('supabaseUrl').value = savedUrl;
        document.getElementById('supabaseKey').value = '********';
    }
});

// Save credentials (optional)
function saveCredentials() {
    const url = document.getElementById('supabaseUrl').value;
    const key = document.getElementById('supabaseKey').value;
    
    if (url && key) {
        localStorage.setItem('supabase_url', url);
        localStorage.setItem('supabase_key', key);
        alert('Credentials saved');
    }
}

// In js/admin.js, update the connectSupabase function:

async function connectSupabase() {
    // Use the globally defined credentials
    const url = window.SUPABASE_URL;  // Now uses hardcoded URL
    const key = window.SUPABASE_ANON_KEY;  // Now uses hardcoded key
    
    console.log('Connecting with hardcoded credentials:', url);
    
    if (!url || !key) {
        alert('Credentials not found in code!');
        return;
    }
    
    try {
        // Initialize Supabase client
        adminState.supabaseClient = supabase.createClient();
        
        // Test connection
        const { data, error } = await adminState.supabaseClient
            .from('dialogues')
            .select('count')
            .limit(1);
            
        if (error) throw error;
        
        adminState.connected = true;
        updateConnectionStatus(true);
        alert('✅ Successfully connected to Supabase with hardcoded credentials!');
        
        // Preview default table
        previewTableData();
        
    } catch (error) {
        console.error('Connection error:', error);
        adminState.connected = false;
        updateConnectionStatus(false);
        alert('❌ Connection failed: ' + error.message);
    }
}