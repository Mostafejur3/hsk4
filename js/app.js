// =============================================
// HSK 4 Learning Platform - Supabase Connection
// =============================================

// 🔴 PASTE YOUR SUPABASE CREDENTIALS HERE 🔴
const SUPABASE_URL = "https://iarkghtouitlqvsphcja.supabase.co";     // <-- PASTE YOUR URL HERE
const SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlhcmtnaHRvdWl0bHF2c3BoY2phIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMxMzk3OTAsImV4cCI6MjA4ODcxNTc5MH0.eLOAbk2yLTdeEk4Zr41SbcPyoX9bp-Y-bwisEQYTSRI";  // <-- PASTE YOUR ANON KEY HERE

// Supabase client initialization
const supabase = (function() {
    console.log('Initializing Supabase with hardcoded credentials...');
    console.log('URL:', SUPABASE_URL);
    
    function createClient() {
        return {
            from: function(table) {
                console.log('Accessing table:', table);
                
                return {
                    select: function(columns) {
                        console.log('Selecting columns:', columns);
                        
                        return {
                            limit: async function(n) {
                                console.log(`Fetching ${n} records from ${table}...`);
                                
                                try {
                                    // Make actual API call to Supabase
                                    const response = await fetch(`${SUPABASE_URL}/rest/v1/${table}?select=${columns || '*'}&limit=${n}`, {
                                        headers: {
                                            'apikey': SUPABASE_ANON_KEY,
                                            'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
                                            'Content-Type': 'application/json'
                                        }
                                    });
                                    
                                    if (!response.ok) {
                                        throw new Error(`HTTP error! status: ${response.status}`);
                                    }
                                    
                                    const data = await response.json();
                                    console.log('Data fetched successfully:', data);
                                    return { data, error: null };
                                    
                                } catch (error) {
                                    console.error('Supabase fetch error:', error);
                                    return { data: null, error };
                                }
                            },
                            
                            eq: function(column, value) {
                                console.log(`Filtering where ${column} = ${value}`);
                                // Add filtering logic here
                                return this;
                            },
                            
                            order: function(column, options = {}) {
                                console.log(`Ordering by ${column}`);
                                return this;
                            }
                        };
                    },
                    
                    insert: function(data) {
                        console.log('Inserting data:', data);
                        
                        return {
                            then: async function(callback) {
                                try {
                                    const response = await fetch(`${SUPABASE_URL}/rest/v1/${table}`, {
                                        method: 'POST',
                                        headers: {
                                            'apikey': SUPABASE_ANON_KEY,
                                            'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
                                            'Content-Type': 'application/json',
                                            'Prefer': 'return=representation'
                                        },
                                        body: JSON.stringify(Array.isArray(data) ? data : [data])
                                    });
                                    
                                    if (!response.ok) {
                                        throw new Error(`HTTP error! status: ${response.status}`);
                                    }
                                    
                                    const result = await response.json();
                                    callback({ data: result, error: null });
                                    
                                } catch (error) {
                                    console.error('Insert error:', error);
                                    callback({ data: null, error });
                                }
                            }
                        };
                    },
                    
                    delete: function() {
                        return {
                            match: function(criteria) {
                                console.log('Deleting with criteria:', criteria);
                                return {
                                    then: async function(callback) {
                                        try {
                                            // Build where clause from criteria
                                            const whereClause = Object.entries(criteria)
                                                .map(([key, value]) => `${key}=eq.${value}`)
                                                .join('&');
                                            
                                            const response = await fetch(`${SUPABASE_URL}/rest/v1/${table}?${whereClause}`, {
                                                method: 'DELETE',
                                                headers: {
                                                    'apikey': SUPABASE_ANON_KEY,
                                                    'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
                                                    'Content-Type': 'application/json',
                                                    'Prefer': 'return=representation'
                                                }
                                            });
                                            
                                            if (!response.ok) {
                                                throw new Error(`HTTP error! status: ${response.status}`);
                                            }
                                            
                                            const result = await response.json();
                                            callback({ data: result, error: null });
                                            
                                        } catch (error) {
                                            console.error('Delete error:', error);
                                            callback({ data: null, error });
                                        }
                                    }
                                };
                            }
                        };
                    }
                };
            }
        };
    }
    
    return {
        createClient: createClient
    };
})();

// Make supabase available globally
window.supabase = supabase;
window.SUPABASE_URL = SUPABASE_URL;
window.SUPABASE_ANON_KEY = SUPABASE_ANON_KEY;

console.log('Supabase module loaded with hardcoded credentials');





// Main Application State
let currentState = {
    contentType: 'dialogues',
    currentIndex: 0,
    showPinyin: false,
    showTranslation: false,
    userAnswers: [],
    progress: {}
};

// Section data counts
const sectionCounts = {
    dialogues: window.HSK4Data?.dialogues?.length || 3,
    short: window.HSK4Data?.shortTexts?.length || 2,
    long: window.HSK4Data?.longTexts?.length || 1,
    fill: window.HSK4Data?.fillBlanks?.length || 5,
    mcq: window.HSK4Data?.mcqs?.length || 10
};

// Section names in Chinese
const sectionNames = {
    dialogues: '对话',
    short: '短文',
    long: '长文',
    fill: '填空',
    mcq: '选择'
};

// Initialize the application
document.addEventListener('DOMContentLoaded', () => {
    console.log('HSK 4 Platform Initializing with 宋体 font...');
    initializeApp();
    loadUserProgress();
    setupEventListeners();
    updateSectionProgress();
});

function initializeApp() {
    // Load first content
    updateContent();
    updateProgressBar();
    updateActiveNavLink('dialogues');
    setupAdminShortcut();
}

function setupEventListeners() {
    // Navigation links
    document.querySelectorAll('.nav-link').forEach(link => {
        link.addEventListener('click', (e) => {
            e.preventDefault();
            const section = link.dataset.section;
            console.log('Navigation clicked:', section);
            
            // Update active state
            document.querySelectorAll('.nav-link').forEach(l => l.classList.remove('active'));
            link.classList.add('active');
            
            // Update content type
            currentState.contentType = section;
            currentState.currentIndex = 0;
            currentState.userAnswers = [];
            
            // Update UI
            updateContent();
            updateSectionProgress();
            updateNavigationButtons();
            hideResults();
        });
    });

    // Toggle buttons
    document.getElementById('togglePinyin').addEventListener('click', () => {
        currentState.showPinyin = !currentState.showPinyin;
        const pinyinEl = document.getElementById('pinyinText');
        const btn = document.getElementById('togglePinyin');
        
        if (currentState.showPinyin) {
            pinyinEl.classList.remove('hidden');
            btn.classList.add('active');
            btn.innerHTML = '<i class="fas fa-language"></i><span>隐藏拼音</span>';
        } else {
            pinyinEl.classList.add('hidden');
            btn.classList.remove('active');
            btn.innerHTML = '<i class="fas fa-language"></i><span>显示拼音</span>';
        }
    });

    document.getElementById('toggleTranslation').addEventListener('click', () => {
        currentState.showTranslation = !currentState.showTranslation;
        const translationEl = document.getElementById('translationText');
        const btn = document.getElementById('toggleTranslation');
        
        if (currentState.showTranslation) {
            translationEl.classList.remove('hidden');
            btn.classList.add('active');
            btn.innerHTML = '<i class="fas fa-globe"></i><span>隐藏翻译</span>';
        } else {
            translationEl.classList.add('hidden');
            btn.classList.remove('active');
            btn.innerHTML = '<i class="fas fa-globe"></i><span>显示翻译</span>';
        }
    });

    // Navigation buttons
    document.getElementById('prevBtn').addEventListener('click', () => {
        if (currentState.currentIndex > 0) {
            currentState.currentIndex--;
            updateContent();
            updateNavigationButtons();
            updateSectionProgress();
        }
    });

    document.getElementById('nextBtn').addEventListener('click', () => {
        const total = getTotalItems();
        if (currentState.currentIndex < total - 1) {
            currentState.currentIndex++;
            updateContent();
            updateNavigationButtons();
            updateSectionProgress();
        }
    });

    // Submit button
    document.getElementById('submitBtn').addEventListener('click', submitAnswers);
}

function updateActiveNavLink(section) {
    document.querySelectorAll('.nav-link').forEach(link => {
        if (link.dataset.section === section) {
            link.classList.add('active');
        } else {
            link.classList.remove('active');
        }
    });
}

function updateSectionProgress() {
    const completed = currentState.currentIndex + 1;
    const total = sectionCounts[currentState.contentType] || 10;
    
    document.getElementById('sectionName').textContent = sectionNames[currentState.contentType] || currentState.contentType;
    document.getElementById('progressText').textContent = `${completed}/${total}`;
    document.getElementById('completedCount').textContent = completed;
    document.getElementById('totalCount').textContent = total;
    
    const percentage = Math.round((completed / total) * 100);
    document.getElementById('progressFill').style.width = percentage + '%';
}

function updateContent() {
    const content = getCurrentContent();
    if (!content) return;

    // Update title
    document.getElementById('contentTitle').textContent = 
        `${sectionNames[currentState.contentType]} ${currentState.currentIndex + 1}/${getTotalItems()}`;

    // Update Chinese text
    document.getElementById('chineseText').textContent = content.chinese || content.text || content.question || content.sentence || '';

    // Update Pinyin
    document.getElementById('pinyinText').textContent = content.pinyin || '';

    // Update Translation
    document.getElementById('translationText').textContent = content.english || content.translation || '';

    // Handle different content types
    handleContentTypeSpecific(content);
}

function handleContentTypeSpecific(content) {
    const optionsContainer = document.getElementById('optionsContainer');
    const submitBtn = document.getElementById('submitBtn');
    
    // Hide options and submit by default
    optionsContainer.classList.add('hidden');
    submitBtn.classList.add('hidden');
    
    if (currentState.contentType === 'fill' || currentState.contentType === 'mcq') {
        optionsContainer.classList.remove('hidden');
        submitBtn.classList.remove('hidden');
        
        if (currentState.contentType === 'fill') {
            renderFillBlankOptions(content);
        } else {
            renderMcqOptions(content);
        }
    }
}

function renderFillBlankOptions(content) {
    const optionsContainer = document.getElementById('optionsContainer');
    let html = '<div class="fill-blank">';
    
    // Split the sentence and insert blank
    const parts = content.sentence.split('________');
    html += `<div class="sentence">${parts[0]} <span class="blank">______</span> ${parts[1] || ''}</div>`;
    
    // Render word options
    html += '<div class="word-options">';
    content.options.forEach((option, index) => {
        html += `
            <div class="word-option" data-index="${index}" onclick="selectWordOption(this, ${index})">
                ${option}
            </div>
        `;
    });
    html += '</div></div>';
    
    optionsContainer.innerHTML = html;
}

function renderMcqOptions(content) {
    const optionsContainer = document.getElementById('optionsContainer');
    let html = '<div class="mcq-options">';
    
    content.options.forEach((option, index) => {
        const letter = String.fromCharCode(65 + index); // A, B, C, D
        html += `
            <div class="option-item" data-index="${index}" onclick="selectMcqOption(this, ${index})">
                <span class="option-label">${letter}.</span>
                ${option}
            </div>
        `;
    });
    html += '</div>';
    
    optionsContainer.innerHTML = html;
}

// Global functions for option selection
window.selectWordOption = function(element, index) {
    document.querySelectorAll('.word-option').forEach(el => el.classList.remove('selected'));
    element.classList.add('selected');
    currentState.userAnswers[currentState.currentIndex] = index;
};

window.selectMcqOption = function(element, index) {
    document.querySelectorAll('.option-item').forEach(el => el.classList.remove('selected'));
    element.classList.add('selected');
    currentState.userAnswers[currentState.currentIndex] = index;
};

function submitAnswers() {
    const content = getCurrentContent();
    const userAnswer = currentState.userAnswers[currentState.currentIndex];
    
    if (userAnswer === undefined) {
        alert('请选择一个答案！');
        return;
    }
    
    const isCorrect = userAnswer === content.correctAnswer;
    
    // Show result for current question
    showResult(content, userAnswer, isCorrect);
}

function showResult(content, userAnswer, isCorrect) {
    const resultsSection = document.getElementById('resultsSection');
    const resultsGrid = document.getElementById('resultsGrid');
    
    resultsSection.classList.remove('hidden');
    
    const resultHtml = `
        <div class="result-item ${isCorrect ? 'correct' : 'incorrect'}">
            <div class="result-question">${content.question || content.sentence}</div>
            <div class="result-answer">
                <div class="your-answer">你的答案: ${content.options[userAnswer]}</div>
                <div class="correct-answer">正确答案: ${content.options[content.correctAnswer]}</div>
            </div>
            <div class="result-explanation">
                <p><strong>解释:</strong></p>
                <p>${content.explanation || ''}</p>
                <p class="pinyin-explanation">${content.pinyinExplanation || ''}</p>
            </div>
        </div>
    `;
    
    resultsGrid.innerHTML = resultHtml;
}

function hideResults() {
    document.getElementById('resultsSection').classList.add('hidden');
}

function getCurrentContent() {
    const data = window.HSK4Data || {};
    const contentType = currentState.contentType;
    const index = currentState.currentIndex;
    
    if (contentType === 'dialogues' && data.dialogues) {
        return data.dialogues[index];
    } else if (contentType === 'short' && data.shortTexts) {
        return data.shortTexts[index];
    } else if (contentType === 'long' && data.longTexts) {
        return data.longTexts[index];
    } else if (contentType === 'fill' && data.fillBlanks) {
        return data.fillBlanks[index];
    } else if (contentType === 'mcq' && data.mcqs) {
        return data.mcqs[index];
    }
    
    return null;
}

function getTotalItems() {
    return sectionCounts[currentState.contentType] || 10;
}

function updateNavigationButtons() {
    const prevBtn = document.getElementById('prevBtn');
    const nextBtn = document.getElementById('nextBtn');
    const total = getTotalItems();
    
    prevBtn.disabled = currentState.currentIndex === 0;
    nextBtn.disabled = currentState.currentIndex === total - 1;
    
    document.getElementById('currentIndex').textContent = currentState.currentIndex + 1;
    document.getElementById('totalItems').textContent = total;
}

function updateProgressBar() {
    updateSectionProgress();
    updateNavigationButtons();
}

function loadUserProgress() {
    // Load from localStorage
    const saved = localStorage.getItem('hsk4_progress');
    if (saved) {
        try {
            currentState.progress = JSON.parse(saved);
        } catch (e) {
            console.log('No saved progress');
        }
    }
}

function saveUserProgress() {
    localStorage.setItem('hsk4_progress', JSON.stringify(currentState.progress));
}

function setupAdminShortcut() {
    document.addEventListener('keydown', (e) => {
        if (e.ctrlKey && e.shiftKey && e.key === 'A') {
            e.preventDefault();
            const accessKey = prompt('请输入管理员密码:');
            if (accessKey === '140506') {
                window.location.href = 'admin.html';
            } else {
                alert('密码错误！');
            }
        }
    });
    
    document.querySelector('.admin-shortcut').addEventListener('click', () => {
        const accessKey = prompt('请输入管理员密码:');
        if (accessKey === '140506') {
            window.location.href = 'admin.html';
        } else {
            alert('密码错误！');
        }
    });
}



// In js/app.js, add this function to fetch real data:

async function fetchDataFromSupabase() {
    if (!window.supabaseClient) {
        window.supabaseClient = supabase.createClient();
    }
    
    try {
        // Fetch dialogues
        const { data: dialogues, error: dError } = await window.supabaseClient
            .from('dialogues')
            .select('*')
            .limit(100);
            
        if (!dError && dialogues) {
            window.HSK4Data.dialogues = dialogues;
        }
        
        // Fetch fill in blanks
        const { data: fillBlanks, error: fError } = await window.supabaseClient
            .from('fill_blanks')
            .select('*')
            .limit(50);
            
        if (!fError && fillBlanks) {
            window.HSK4Data.fillBlanks = fillBlanks;
        }
        
        // Fetch MCQs
        const { data: mcqs, error: mError } = await window.supabaseClient
            .from('mcqs')
            .select('*')
            .limit(100);
            
        if (!mError && mcqs) {
            window.HSK4Data.mcqs = mcqs;
        }
        
        console.log('Data fetched from Supabase successfully!');
        updateContent(); // Refresh content with real data
        
    } catch (error) {
        console.error('Error fetching from Supabase:', error);
    }
}