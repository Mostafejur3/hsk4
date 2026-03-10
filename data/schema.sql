-- =====================================================
-- HSK 4 Learning Platform - Complete Database Schema
-- =====================================================

-- Enable UUID extension for user IDs
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- 1. DIALOGUES TABLE
-- =====================================================
CREATE TABLE dialogues (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    chinese_text TEXT NOT NULL,
    pinyin TEXT NOT NULL,
    english_translation TEXT NOT NULL,
    category VARCHAR(50) DEFAULT 'general',
    difficulty_level VARCHAR(10) DEFAULT 'HSK4',
    tags TEXT[] DEFAULT '{}',
    order_index INTEGER,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    
    -- Constraints
    CONSTRAINT chk_chinese_text_length CHECK (char_length(chinese_text) >= 10),
    CONSTRAINT chk_difficulty_level CHECK (difficulty_level IN ('HSK1', 'HSK2', 'HSK3', 'HSK4', 'HSK5', 'HSK6'))
);

-- Indexes for dialogues
CREATE INDEX idx_dialogues_category ON dialogues(category);
CREATE INDEX idx_dialogues_difficulty ON dialogues(difficulty_level);
CREATE INDEX idx_dialogues_order ON dialogues(order_index);
CREATE INDEX idx_dialogues_active ON dialogues(is_active);
CREATE INDEX idx_dialogues_created ON dialogues(created_at DESC);

-- Comments
COMMENT ON TABLE dialogues IS 'Stores all dialogue-based learning materials';
COMMENT ON COLUMN dialogues.chinese_text IS 'The dialogue text in Chinese characters';
COMMENT ON COLUMN dialogues.pinyin IS 'Pinyin pronunciation with tone marks';
COMMENT ON COLUMN dialogues.english_translation IS 'English translation of the dialogue';

-- =====================================================
-- 2. READING TEXTS TABLE
-- =====================================================
CREATE TABLE reading_texts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(200) NOT NULL,
    chinese_text TEXT NOT NULL,
    pinyin TEXT NOT NULL,
    english_translation TEXT NOT NULL,
    text_type VARCHAR(20) NOT NULL, -- 'short' or 'long'
    category VARCHAR(50) DEFAULT 'general',
    difficulty_level VARCHAR(10) DEFAULT 'HSK4',
    word_count INTEGER,
    estimated_time_minutes INTEGER,
    tags TEXT[] DEFAULT '{}',
    questions JSONB NOT NULL DEFAULT '[]',
    is_active BOOLEAN DEFAULT true,
    order_index INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    
    -- Constraints
    CONSTRAINT chk_text_type CHECK (text_type IN ('short', 'long')),
    CONSTRAINT chk_word_count CHECK (word_count > 0),
    CONSTRAINT chk_questions_format CHECK (jsonb_typeof(questions) = 'array')
);

-- Indexes for reading texts
CREATE INDEX idx_reading_texts_type ON reading_texts(text_type);
CREATE INDEX idx_reading_texts_category ON reading_texts(category);
CREATE INDEX idx_reading_texts_difficulty ON reading_texts(difficulty_level);
CREATE INDEX idx_reading_texts_word_count ON reading_texts(word_count);
CREATE INDEX idx_reading_texts_gin_tags ON reading_texts USING gin(tags);
CREATE INDEX idx_reading_texts_gin_questions ON reading_texts USING gin(questions);

-- Comments
COMMENT ON TABLE reading_texts IS 'Stores short and long reading passages with comprehension questions';
COMMENT ON COLUMN reading_texts.questions IS 'JSON array of questions with options, correct answers, and explanations';

-- =====================================================
-- 3. FILL IN THE BLANKS TABLE
-- =====================================================
CREATE TABLE fill_blanks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sentence TEXT NOT NULL,
    options TEXT[] NOT NULL,
    correct_answer INTEGER NOT NULL,
    explanation TEXT,
    pinyin_explanation TEXT,
    grammar_point VARCHAR(100),
    vocabulary_focus TEXT[],
    difficulty_level VARCHAR(10) DEFAULT 'HSK4',
    category VARCHAR(50) DEFAULT 'grammar',
    tags TEXT[] DEFAULT '{}',
    is_active BOOLEAN DEFAULT true,
    order_index INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    
    -- Constraints
    CONSTRAINT chk_options_length CHECK (array_length(options, 1) BETWEEN 4 AND 6),
    CONSTRAINT chk_correct_answer_range CHECK (correct_answer >= 0 AND correct_answer < array_length(options, 1)),
    CONSTRAINT chk_difficulty_level CHECK (difficulty_level IN ('HSK1', 'HSK2', 'HSK3', 'HSK4', 'HSK5', 'HSK6'))
);

-- Indexes for fill blanks
CREATE INDEX idx_fill_blanks_grammar ON fill_blanks(grammar_point);
CREATE INDEX idx_fill_blanks_difficulty ON fill_blanks(difficulty_level);
CREATE INDEX idx_fill_blanks_category ON fill_blanks(category);
CREATE INDEX idx_fill_blanks_gin_vocab ON fill_blanks USING gin(vocabulary_focus);

-- =====================================================
-- 4. MULTIPLE CHOICE QUESTIONS TABLE
-- =====================================================
CREATE TABLE mcqs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    question TEXT NOT NULL,
    options TEXT[] NOT NULL,
    correct_answer INTEGER NOT NULL,
    explanation TEXT,
    pinyin_explanation TEXT,
    question_type VARCHAR(30) DEFAULT 'vocabulary', -- vocabulary, grammar, comprehension
    difficulty_level VARCHAR(10) DEFAULT 'HSK4',
    category VARCHAR(50) DEFAULT 'general',
    tags TEXT[] DEFAULT '{}',
    reading_passage_id UUID REFERENCES reading_texts(id) ON DELETE CASCADE,
    is_active BOOLEAN DEFAULT true,
    order_index INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    
    -- Constraints
    CONSTRAINT chk_options_length CHECK (array_length(options, 1) = 4),
    CONSTRAINT chk_correct_answer_range CHECK (correct_answer >= 0 AND correct_answer <= 3),
    CONSTRAINT chk_question_type CHECK (question_type IN ('vocabulary', 'grammar', 'comprehension', 'listening'))
);

-- Indexes for MCQs
CREATE INDEX idx_mcqs_type ON mcqs(question_type);
CREATE INDEX idx_mcqs_difficulty ON mcqs(difficulty_level);
CREATE INDEX idx_mcqs_category ON mcqs(category);
CREATE INDEX idx_mcqs_reading_passage ON mcqs(reading_passage_id);
CREATE INDEX idx_mcqs_gin_tags ON mcqs USING gin(tags);

-- =====================================================
-- 5. VOCABULARY TABLE
-- =====================================================
CREATE TABLE vocabulary (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    word VARCHAR(50) NOT NULL,
    pinyin VARCHAR(100) NOT NULL,
    english_meaning TEXT NOT NULL,
    part_of_speech VARCHAR(30),
    example_sentence TEXT,
    example_sentence_pinyin TEXT,
    example_sentence_english TEXT,
    hsk_level VARCHAR(10) DEFAULT 'HSK4',
    frequency INTEGER DEFAULT 1,
    tags TEXT[] DEFAULT '{}',
    notes TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    
    -- Constraints
    CONSTRAINT chk_hsk_level CHECK (hsk_level IN ('HSK1', 'HSK2', 'HSK3', 'HSK4', 'HSK5', 'HSK6')),
    CONSTRAINT chk_frequency CHECK (frequency >= 1),
    CONSTRAINT unique_word UNIQUE(word)
);

-- Indexes for vocabulary
CREATE INDEX idx_vocabulary_word ON vocabulary(word);
CREATE INDEX idx_vocabulary_hsk_level ON vocabulary(hsk_level);
CREATE INDEX idx_vocabulary_frequency ON vocabulary(frequency DESC);
CREATE INDEX idx_vocabulary_gin_tags ON vocabulary USING gin(tags);
CREATE INDEX idx_vocabulary_part_of_speech ON vocabulary(part_of_speech);

-- =====================================================
-- 6. GRAMMAR POINTS TABLE
-- =====================================================
CREATE TABLE grammar_points (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pattern VARCHAR(100) NOT NULL,
    explanation TEXT NOT NULL,
    pinyin_explanation TEXT,
    english_explanation TEXT NOT NULL,
    structure TEXT,
    examples JSONB NOT NULL DEFAULT '[]',
    hsk_level VARCHAR(10) DEFAULT 'HSK4',
    category VARCHAR(50),
    tags TEXT[] DEFAULT '{}',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    
    -- Constraints
    CONSTRAINT chk_examples_format CHECK (jsonb_typeof(examples) = 'array'),
    CONSTRAINT unique_pattern UNIQUE(pattern)
);

-- Indexes for grammar points
CREATE INDEX idx_grammar_pattern ON grammar_points(pattern);
CREATE INDEX idx_grammar_hsk_level ON grammar_points(hsk_level);
CREATE INDEX idx_grammar_category ON grammar_points(category);
CREATE INDEX idx_grammar_gin_tags ON grammar_points USING gin(tags);

-- =====================================================
-- 7. USERS TABLE (extends Supabase auth.users)
-- =====================================================
CREATE TABLE users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username VARCHAR(50) UNIQUE,
    display_name VARCHAR(100),
    avatar_url TEXT,
    native_language VARCHAR(50) DEFAULT 'English',
    target_hsk_level VARCHAR(10) DEFAULT 'HSK4',
    daily_goal_minutes INTEGER DEFAULT 15,
    learning_streak INTEGER DEFAULT 0,
    total_learning_days INTEGER DEFAULT 0,
    last_active_date DATE DEFAULT CURRENT_DATE,
    preferences JSONB DEFAULT '{
        "showPinyinByDefault": false,
        "showTranslationByDefault": false,
        "fontSize": "large",
        "notifications": true
    }',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT chk_daily_goal CHECK (daily_goal_minutes BETWEEN 5 AND 240)
);

-- Indexes for users
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_hsk_level ON users(target_hsk_level);
CREATE INDEX idx_users_last_active ON users(last_active_date DESC);

-- =====================================================
-- 8. USER PROGRESS TABLE
-- =====================================================
CREATE TABLE user_progress (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content_type VARCHAR(20) NOT NULL, -- dialogue, reading, fill_blank, mcq, vocabulary
    content_id UUID NOT NULL,
    status VARCHAR(20) DEFAULT 'not_started', -- not_started, in_progress, completed
    score INTEGER,
    max_score INTEGER,
    time_spent_seconds INTEGER DEFAULT 0,
    attempts INTEGER DEFAULT 0,
    last_question_index INTEGER DEFAULT 0,
    answers_given JSONB DEFAULT '[]',
    is_correct BOOLEAN,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT chk_content_type CHECK (content_type IN ('dialogue', 'reading', 'fill_blank', 'mcq', 'vocabulary')),
    CONSTRAINT chk_status CHECK (status IN ('not_started', 'in_progress', 'completed')),
    CONSTRAINT chk_score_range CHECK (score >= 0 AND score <= max_score),
    CONSTRAINT unique_user_content UNIQUE(user_id, content_type, content_id)
);

-- Indexes for user progress
CREATE INDEX idx_user_progress_user ON user_progress(user_id);
CREATE INDEX idx_user_progress_status ON user_progress(status);
CREATE INDEX idx_user_progress_completed ON user_progress(completed_at) WHERE status = 'completed';
CREATE INDEX idx_user_progress_content ON user_progress(content_type, content_id);
CREATE INDEX idx_user_progress_updated ON user_progress(updated_at DESC);

-- =====================================================
-- 9. USER ACHIEVEMENTS TABLE
-- =====================================================
CREATE TABLE achievements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    description TEXT NOT NULL,
    badge_icon TEXT,
    points INTEGER DEFAULT 10,
    criteria JSONB NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT unique_achievement_name UNIQUE(name)
);

CREATE TABLE user_achievements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    achievement_id UUID NOT NULL REFERENCES achievements(id) ON DELETE CASCADE,
    earned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT unique_user_achievement UNIQUE(user_id, achievement_id)
);

-- Indexes
CREATE INDEX idx_user_achievements_user ON user_achievements(user_id);
CREATE INDEX idx_user_achievements_earned ON user_achievements(earned_at DESC);

-- =====================================================
-- 10. STUDY SESSIONS TABLE
-- =====================================================
CREATE TABLE study_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    start_time TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    end_time TIMESTAMP WITH TIME ZONE,
    duration_minutes INTEGER,
    content_studied JSONB DEFAULT '[]',
    items_completed INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for study sessions
CREATE INDEX idx_study_sessions_user ON study_sessions(user_id);
CREATE INDEX idx_study_sessions_start ON study_sessions(start_time DESC);
CREATE INDEX idx_study_sessions_duration ON study_sessions(duration_minutes) WHERE duration_minutes IS NOT NULL;

-- =====================================================
-- 11. MISTAKES/REVIEW TABLE (Spaced Repetition)
-- =====================================================
CREATE TABLE review_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content_type VARCHAR(20) NOT NULL,
    content_id UUID NOT NULL,
    ease_factor FLOAT DEFAULT 2.5,
    interval_days INTEGER DEFAULT 1,
    repetitions INTEGER DEFAULT 0,
    next_review_date DATE DEFAULT CURRENT_DATE + INTERVAL '1 day',
    last_reviewed DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT chk_content_type_review CHECK (content_type IN ('dialogue', 'reading', 'fill_blank', 'mcq', 'vocabulary', 'grammar')),
    CONSTRAINT unique_user_review_item UNIQUE(user_id, content_type, content_id)
);

-- Indexes for review items
CREATE INDEX idx_review_items_user ON review_items(user_id);
CREATE INDEX idx_review_items_next_review ON review_items(next_review_date) WHERE next_review_date <= CURRENT_DATE;
CREATE INDEX idx_review_items_content ON review_items(content_type, content_id);

-- =====================================================
-- 12. NOTES/BOOKMARKS TABLE
-- =====================================================
CREATE TABLE user_notes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content_type VARCHAR(20) NOT NULL,
    content_id UUID NOT NULL,
    note_text TEXT NOT NULL,
    is_private BOOLEAN DEFAULT true,
    tags TEXT[] DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT chk_content_type_notes CHECK (content_type IN ('dialogue', 'reading', 'fill_blank', 'mcq', 'vocabulary', 'grammar'))
);

CREATE TABLE bookmarks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content_type VARCHAR(20) NOT NULL,
    content_id UUID NOT NULL,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT unique_user_bookmark UNIQUE(user_id, content_type, content_id)
);

-- Indexes
CREATE INDEX idx_user_notes_user ON user_notes(user_id);
CREATE INDEX idx_bookmarks_user ON bookmarks(user_id);
CREATE INDEX idx_bookmarks_content ON bookmarks(content_type, content_id);

-- =====================================================
-- 13. MOCK TESTS TABLE
-- =====================================================
CREATE TABLE mock_tests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(200) NOT NULL,
    description TEXT,
    test_type VARCHAR(30) DEFAULT 'full', -- full, listening, reading, writing
    hsk_level VARCHAR(10) DEFAULT 'HSK4',
    time_limit_minutes INTEGER DEFAULT 105, -- Official HSK 4 time limit
    total_questions INTEGER,
    passing_score INTEGER DEFAULT 60,
    questions JSONB NOT NULL DEFAULT '[]',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    
    CONSTRAINT chk_test_type CHECK (test_type IN ('full', 'listening', 'reading', 'writing'))
);

CREATE TABLE user_test_results (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    test_id UUID NOT NULL REFERENCES mock_tests(id) ON DELETE CASCADE,
    score INTEGER NOT NULL,
    max_score INTEGER NOT NULL,
    time_spent_minutes INTEGER,
    answers_given JSONB NOT NULL DEFAULT '[]',
    section_scores JSONB DEFAULT '{}',
    passed BOOLEAN,
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT chk_score CHECK (score >= 0 AND score <= max_score)
);

-- Indexes for tests
CREATE INDEX idx_mock_tests_level ON mock_tests(hsk_level);
CREATE INDEX idx_mock_tests_type ON mock_tests(test_type);
CREATE INDEX idx_user_test_results_user ON user_test_results(user_id);
CREATE INDEX idx_user_test_results_completed ON user_test_results(completed_at DESC);

-- =====================================================
-- 14. ADMIN ACTIVITY LOG
-- =====================================================
CREATE TABLE admin_activity_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    admin_id UUID REFERENCES users(id) ON DELETE SET NULL,
    action VARCHAR(100) NOT NULL,
    target_type VARCHAR(50),
    target_id UUID,
    details JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for admin log
CREATE INDEX idx_admin_log_admin ON admin_activity_log(admin_id);
CREATE INDEX idx_admin_log_action ON admin_activity_log(action);
CREATE INDEX idx_admin_log_created ON admin_activity_log(created_at DESC);

-- =====================================================
-- 15. SYSTEM SETTINGS TABLE
-- =====================================================
CREATE TABLE system_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    setting_key VARCHAR(100) UNIQUE NOT NULL,
    setting_value JSONB NOT NULL,
    description TEXT,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_by UUID REFERENCES users(id)
);

-- Insert default settings
INSERT INTO system_settings (setting_key, setting_value, description) VALUES
    ('site_config', '{"siteName":"HSK 4 Learning Platform","maintenanceMode":false,"allowRegistrations":true}', 'Main site configuration'),
    ('content_settings', '{"defaultHskLevel":"HSK4","showAnswers":true,"allowNotes":true}', 'Default content settings'),
    ('admin_access', '{"accessKey":"140506","maxLoginAttempts":5,"sessionTimeout":30}', 'Admin panel settings'),
    ('feature_flags', '{"enableAudio":true,"enableSpacedRepetition":true,"enableAchievements":true}', 'Feature toggles'),
    ('supabase_config', '{"maxConnections":100,"timeout":30,"poolSize":20}', 'Database connection settings');

-- =====================================================
-- 16. FUNCTIONS AND TRIGGERS
-- =====================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply updated_at triggers to all tables
CREATE TRIGGER update_dialogues_updated_at BEFORE UPDATE ON dialogues
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_reading_texts_updated_at BEFORE UPDATE ON reading_texts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_fill_blanks_updated_at BEFORE UPDATE ON fill_blanks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_mcqs_updated_at BEFORE UPDATE ON mcqs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_vocabulary_updated_at BEFORE UPDATE ON vocabulary
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_grammar_points_updated_at BEFORE UPDATE ON grammar_points
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_progress_updated_at BEFORE UPDATE ON user_progress
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_review_items_updated_at BEFORE UPDATE ON review_items
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_notes_updated_at BEFORE UPDATE ON user_notes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_mock_tests_updated_at BEFORE UPDATE ON mock_tests
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to update user streak
CREATE OR REPLACE FUNCTION update_user_streak()
RETURNS TRIGGER AS $$
BEGIN
    -- Update streak when user is active
    UPDATE users 
    SET 
        last_active_date = CURRENT_DATE,
        learning_streak = CASE 
            WHEN last_active_date = CURRENT_DATE - INTERVAL '1 day' THEN learning_streak + 1
            WHEN last_active_date < CURRENT_DATE - INTERVAL '1 day' THEN 1
            ELSE learning_streak
        END,
        total_learning_days = CASE 
            WHEN last_active_date < CURRENT_DATE THEN total_learning_days + 1
            ELSE total_learning_days
        END
    WHERE id = NEW.user_id;
    
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger to update streak on study session
CREATE TRIGGER update_user_streak_on_session
    AFTER INSERT ON study_sessions
    FOR EACH ROW
    EXECUTE FUNCTION update_user_streak();

-- Function to calculate user level based on progress
CREATE OR REPLACE FUNCTION calculate_user_level(user_uuid UUID)
RETURNS TABLE (
    current_level VARCHAR(10),
    progress_percentage INTEGER,
    next_level VARCHAR(10),
    points_to_next INTEGER
) AS $$
DECLARE
    total_items INTEGER;
    completed_items INTEGER;
    percentage INTEGER;
BEGIN
    -- Count total available items
    SELECT COUNT(*) INTO total_items FROM (
        SELECT id FROM dialogues WHERE is_active = true
        UNION ALL
        SELECT id FROM reading_texts WHERE is_active = true
        UNION ALL
        SELECT id FROM fill_blanks WHERE is_active = true
        UNION ALL
        SELECT id FROM mcqs WHERE is_active = true
    ) AS all_items;
    
    -- Count completed items for user
    SELECT COUNT(*) INTO completed_items 
    FROM user_progress 
    WHERE user_id = user_uuid AND status = 'completed';
    
    -- Calculate percentage
    percentage := (completed_items * 100 / total_items);
    
    -- Determine level
    RETURN QUERY
    SELECT 
        CASE 
            WHEN percentage < 20 THEN 'HSK1'
            WHEN percentage < 40 THEN 'HSK2'
            WHEN percentage < 60 THEN 'HSK3'
            WHEN percentage < 80 THEN 'HSK4'
            WHEN percentage < 95 THEN 'HSK5'
            ELSE 'HSK6'
        END as current_level,
        percentage as progress_percentage,
        CASE 
            WHEN percentage < 20 THEN 'HSK2'
            WHEN percentage < 40 THEN 'HSK3'
            WHEN percentage < 60 THEN 'HSK4'
            WHEN percentage < 80 THEN 'HSK5'
            WHEN percentage < 95 THEN 'HSK6'
            ELSE 'Master'
        END as next_level,
        CASE 
            WHEN percentage < 20 THEN (20 - percentage) * total_items / 100
            WHEN percentage < 40 THEN (40 - percentage) * total_items / 100
            WHEN percentage < 60 THEN (60 - percentage) * total_items / 100
            WHEN percentage < 80 THEN (80 - percentage) * total_items / 100
            WHEN percentage < 95 THEN (95 - percentage) * total_items / 100
            ELSE 0
        END as points_to_next;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 17. VIEWS FOR COMMON QUERIES
-- =====================================================

-- View for user dashboard summary
CREATE VIEW user_dashboard_summary AS
SELECT 
    u.id as user_id,
    u.username,
    u.display_name,
    u.learning_streak,
    u.total_learning_days,
    u.daily_goal_minutes,
    COALESCE(SUM(ss.duration_minutes), 0) as total_minutes_studied,
    COALESCE(AVG(ss.duration_minutes), 0) as avg_session_duration,
    COUNT(DISTINCT ss.id) as total_sessions,
    COUNT(DISTINCT up.id) as total_items_completed,
    COUNT(DISTINCT b.id) as total_bookmarks,
    COUNT(DISTINCT ri.id) as items_for_review
FROM users u
LEFT JOIN study_sessions ss ON u.id = ss.user_id
LEFT JOIN user_progress up ON u.id = up.user_id AND up.status = 'completed'
LEFT JOIN bookmarks b ON u.id = b.user_id
LEFT JOIN review_items ri ON u.id = ri.user_id AND ri.next_review_date <= CURRENT_DATE
GROUP BY u.id;

-- View for content popularity
CREATE VIEW content_popularity AS
SELECT 
    up.content_type,
    up.content_id,
    CASE 
        WHEN up.content_type = 'dialogue' THEN d.chinese_text
        WHEN up.content_type = 'reading' THEN rt.title
        WHEN up.content_type = 'fill_blank' THEN fb.sentence
        WHEN up.content_type = 'mcq' THEN m.question
    END as content_preview,
    COUNT(DISTINCT up.user_id) as total_users,
    COUNT(CASE WHEN up.status = 'completed' THEN 1 END) as completions,
    AVG(CASE WHEN up.score IS NOT NULL THEN up.score * 1.0 / up.max_score END) as avg_score,
    SUM(up.time_spent_seconds) as total_time_spent
FROM user_progress up
LEFT JOIN dialogues d ON up.content_type = 'dialogue' AND up.content_id = d.id
LEFT JOIN reading_texts rt ON up.content_type = 'reading' AND up.content_id = rt.id
LEFT JOIN fill_blanks fb ON up.content_type = 'fill_blank' AND up.content_id = fb.id
LEFT JOIN mcqs m ON up.content_type = 'mcq' AND up.content_id = m.id
GROUP BY up.content_type, up.content_id, d.chinese_text, rt.title, fb.sentence, m.question;

-- =====================================================
-- 18. ROW LEVEL SECURITY POLICIES
-- =====================================================

-- Enable RLS on all tables
ALTER TABLE dialogues ENABLE ROW LEVEL SECURITY;
ALTER TABLE reading_texts ENABLE ROW LEVEL SECURITY;
ALTER TABLE fill_blanks ENABLE ROW LEVEL SECURITY;
ALTER TABLE mcqs ENABLE ROW LEVEL SECURITY;
ALTER TABLE vocabulary ENABLE ROW LEVEL SECURITY;
ALTER TABLE grammar_points ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookmarks ENABLE ROW LEVEL SECURITY;
ALTER TABLE review_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE mock_tests ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_test_results ENABLE ROW LEVEL SECURITY;

-- Policies for public content (readable by all authenticated users)
CREATE POLICY "Content viewable by all authenticated users" ON dialogues
    FOR SELECT USING (auth.role() = 'authenticated' AND is_active = true);

CREATE POLICY "Content viewable by all authenticated users" ON reading_texts
    FOR SELECT USING (auth.role() = 'authenticated' AND is_active = true);

CREATE POLICY "Content viewable by all authenticated users" ON fill_blanks
    FOR SELECT USING (auth.role() = 'authenticated' AND is_active = true);

CREATE POLICY "Content viewable by all authenticated users" ON mcqs
    FOR SELECT USING (auth.role() = 'authenticated' AND is_active = true);

-- Policies for user-specific data
CREATE POLICY "Users can view own progress" ON user_progress
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own progress" ON user_progress
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own progress" ON user_progress
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can view own notes" ON user_notes
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own notes" ON user_notes
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can view own bookmarks" ON bookmarks
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own bookmarks" ON bookmarks
    FOR ALL USING (auth.uid() = user_id);

-- Admin policies (access based on admin role)
CREATE POLICY "Admins have full access" ON dialogues
    FOR ALL USING (auth.email() IN (SELECT email FROM users WHERE is_admin = true));

CREATE POLICY "Admins have full access" ON reading_texts
    FOR ALL USING (auth.email() IN (SELECT email FROM users WHERE is_admin = true));

-- Note: You'll need to add an is_admin column to users table if you want admin policies
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_admin BOOLEAN DEFAULT false;

-- =====================================================
-- 19. INSERT SAMPLE ACHIEVEMENTS
-- =====================================================

INSERT INTO achievements (name, description, badge_icon, points, criteria) VALUES
    ('First Steps', 'Complete your first dialogue', '🎯', 10, '{"type":"complete","content":"dialogue","count":1}'),
    ('Bookworm', 'Complete 10 reading texts', '📚', 50, '{"type":"complete","content":"reading","count":10}'),
    ('Grammar Guru', 'Get 20 fill-in-the-blank questions correct', '📝', 100, '{"type":"correct","content":"fill_blank","count":20}'),
    ('Vocabulary Master', 'Learn 100 new words', '🗣️', 200, '{"type":"learn","content":"vocabulary","count":100}'),
    ('Streak Master', 'Maintain a 30-day learning streak', '🔥', 300, '{"type":"streak","days":30}'),
    ('Perfect Score', 'Get 100% on a mock test', '💯', 150, '{"type":"test","score":100}'),
    ('Early Bird', 'Complete 5 study sessions before 8 AM', '🌅', 50, '{"type":"time","hour":"<8","count":5}'),
    ('Night Owl', 'Complete 5 study sessions after 10 PM', '🦉', 50, '{"type":"time","hour":">22","count":5}'),
    ('Social Learner', 'Share 3 notes with the community', '👥', 75, '{"type":"share","count":3}'),
    ('HSK 4 Ready', 'Complete all HSK 4 materials', '🎓', 500, '{"type":"complete_all","level":"HSK4"}');

-- =====================================================
-- 20. CREATE FUNCTIONS FOR ANALYTICS
-- =====================================================

-- Function to get user learning statistics
CREATE OR REPLACE FUNCTION get_user_statistics(user_uuid UUID)
RETURNS TABLE (
    total_study_time INTEGER,
    average_session_length NUMERIC,
    most_active_day TEXT,
    completion_rate NUMERIC,
    strong_topics TEXT[],
    weak_topics TEXT[],
    recommended_next_items JSON
) AS $$
BEGIN
    RETURN QUERY
    WITH user_stats AS (
        SELECT 
            COALESCE(SUM(ss.duration_minutes), 0) as total_time,
            COALESCE(AVG(ss.duration_minutes), 0) as avg_session,
            MODE() WITHIN GROUP (ORDER BY TO_CHAR(ss.start_time, 'Day')) as active_day,
            COUNT(DISTINCT up.id)::NUMERIC / NULLIF(COUNT(DISTINCT 
                CASE WHEN up.status = 'completed' THEN up.id END), 0) * 100 as completion_rate
        FROM users u
        LEFT JOIN study_sessions ss ON u.id = ss.user_id
        LEFT JOIN user_progress up ON u.id = up.user_id
        WHERE u.id = user_uuid
        GROUP BY u.id
    )
    SELECT 
        total_time,
        avg_session,
        active_day,
        completion_rate,
        ARRAY['Vocabulary', 'Grammar'] as strong_topics, -- This would be calculated from actual performance
        ARRAY['Listening', 'Writing'] as weak_topics,
        '{"type":"vocabulary","ids":[1,2,3]}'::JSON as recommended_next_items
    FROM user_stats;
END;
$$ LANGUAGE plpgsql;

-- Function to clean up old data
CREATE OR REPLACE FUNCTION cleanup_old_data()
RETURNS void AS $$
BEGIN
    -- Delete study sessions older than 1 year
    DELETE FROM study_sessions 
    WHERE created_at < NOW() - INTERVAL '1 year';
    
    -- Archive old test results (you might want to move these to an archive table instead)
    DELETE FROM user_test_results 
    WHERE completed_at < NOW() - INTERVAL '6 months';
    
    -- Clean up old review items
    DELETE FROM review_items 
    WHERE next_review_date < NOW() - INTERVAL '3 months'
    AND repetitions > 10; -- Only remove well-learned items
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 21. GRANT PERMISSIONS
-- =====================================================

-- Grant necessary permissions to authenticated users
GRANT SELECT ON dialogues, reading_texts, fill_blanks, mcqs, vocabulary, grammar_points TO authenticated;
GRANT SELECT, INSERT, UPDATE ON user_progress, user_notes, bookmarks, review_items TO authenticated;
GRANT SELECT, INSERT ON study_sessions TO authenticated;
GRANT SELECT, INSERT ON user_test_results TO authenticated;
GRANT SELECT ON user_dashboard_summary TO authenticated;
GRANT SELECT ON content_popularity TO authenticated;

-- Grant all permissions to service role (admin)
GRANT ALL ON ALL TABLES IN SCHEMA public TO service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO service_role;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO service_role;

-- =====================================================
-- 22. CREATE INDEXES FOR PERFORMANCE
-- =====================================================

-- Additional composite indexes for common queries
CREATE INDEX idx_user_progress_composite ON user_progress(user_id, status, content_type);
CREATE INDEX idx_review_items_composite ON review_items(user_id, next_review_date, content_type);
CREATE INDEX idx_study_sessions_composite ON study_sessions(user_id, start_time DESC, duration_minutes);
CREATE INDEX idx_reading_texts_type_level ON reading_texts(text_type, difficulty_level);
CREATE INDEX idx_mcqs_type_difficulty ON mcqs(question_type, difficulty_level);

-- Full-text search indexes
CREATE INDEX idx_dialogues_search ON dialogues USING GIN (to_tsvector('simple', chinese_text));
CREATE INDEX idx_reading_texts_search ON reading_texts USING GIN (to_tsvector('simple', chinese_text));
CREATE INDEX idx_vocabulary_search ON vocabulary USING GIN (to_tsvector('simple', word));

-- =====================================================
-- 23. CREATE TRIGGER FOR NEW USER SETUP
-- =====================================================

CREATE OR REPLACE FUNCTION setup_new_user()
RETURNS TRIGGER AS $$
BEGIN
    -- Insert default preferences
    INSERT INTO users (id, username, display_name, preferences)
    VALUES (
        NEW.id,
        NEW.email,
        split_part(NEW.email, '@', 1),
        '{"showPinyinByDefault": false, "showTranslationByDefault": false, "fontSize": "large", "notifications": true}'
    );
    
    -- Create initial review schedule for basic vocabulary
    INSERT INTO review_items (user_id, content_type, content_id, next_review_date)
    SELECT NEW.id, 'vocabulary', id, CURRENT_DATE + INTERVAL '1 day'
    FROM vocabulary 
    WHERE hsk_level = 'HSK1'
    LIMIT 10;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION setup_new_user();

-- =====================================================
-- 24. COMMENTS FOR DOCUMENTATION
-- =====================================================

COMMENT ON SCHEMA public IS 'HSK 4 Learning Platform Schema';
COMMENT ON TABLE users IS 'Extended user profile information';
COMMENT ON TABLE user_progress IS 'Tracks user progress through learning materials';
COMMENT ON TABLE review_items IS 'Spaced repetition system for review scheduling';
COMMENT ON TABLE achievements IS 'Gamification achievements available';
COMMENT ON TABLE user_achievements IS 'Achievements earned by users';
COMMENT ON TABLE study_sessions IS 'Records of user study sessions';
COMMENT ON TABLE mock_tests IS 'Practice tests in official HSK format';
COMMENT ON TABLE user_test_results IS 'Results from mock tests taken by users';
COMMENT ON TABLE admin_activity_log IS 'Audit log for admin actions';
COMMENT ON TABLE system_settings IS 'Global system configuration settings';

-- =====================================================
-- 25. FINAL NOTES
-- =====================================================

-- This schema is now complete and ready for use with your HSK 4 Learning Platform.
-- To initialize your database, run this entire script in the Supabase SQL editor.
-- After running, you can start adding content through the admin panel.

-- Quick verification query to ensure all tables are created
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;