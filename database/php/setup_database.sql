-- Create the database if it doesn't exist
CREATE DATABASE IF NOT EXISTS ngo_donations;

-- Use the database
USE ngo_donations;

-- Create donations table
CREATE TABLE IF NOT EXISTS donations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    campaign VARCHAR(100),
    recurring BOOLEAN DEFAULT FALSE,
    donation_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    payment_status VARCHAR(20) DEFAULT 'pending',
    transaction_id VARCHAR(100),
    INDEX idx_email (email),
    INDEX idx_donation_date (donation_date)
);

-- Create campaign goals table
CREATE TABLE IF NOT EXISTS campaign_goals (
    id INT AUTO_INCREMENT PRIMARY KEY,
    campaign_name VARCHAR(100) NOT NULL,
    target_amount DECIMAL(10,2) NOT NULL,
    current_amount DECIMAL(10,2) DEFAULT 0,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert default campaign goals
INSERT INTO campaign_goals (campaign_name, target_amount, description) VALUES
('Education for All', 100000, 'Support education for underprivileged children'),
('Healthcare Initiative', 150000, 'Provide healthcare to rural communities'),
('Environmental Protection', 200000, 'Protect and restore natural habitats'),
('Women Empowerment', 80000, 'Support women\'s education and skill development'),
('Clean Water Project', 120000, 'Provide clean water access to communities')
ON DUPLICATE KEY UPDATE
    target_amount = VALUES(target_amount),
    description = VALUES(description);

-- Create indexes for better performance
CREATE INDEX idx_campaign_name ON donations(campaign);
CREATE INDEX idx_donation_date ON donations(donation_date);
CREATE INDEX idx_campaign_goals_name ON campaign_goals(campaign_name);

-- Create a view for campaign progress
CREATE OR REPLACE VIEW campaign_progress AS
SELECT 
    cg.campaign_name,
    cg.target_amount,
    cg.current_amount,
    cg.description,
    ROUND((cg.current_amount / cg.target_amount) * 100, 2) as progress_percentage,
    COUNT(d.id) as total_donations,
    SUM(d.amount) as total_raised
FROM campaign_goals cg
LEFT JOIN donations d ON cg.campaign_name = d.campaign
GROUP BY cg.campaign_name, cg.target_amount, cg.current_amount, cg.description;

-- Create a trigger to update campaign progress
DELIMITER //
CREATE TRIGGER after_donation_insert
AFTER INSERT ON donations
FOR EACH ROW
BEGIN
    IF NEW.campaign IS NOT NULL THEN
        UPDATE campaign_goals 
        SET current_amount = current_amount + NEW.amount
        WHERE campaign_name = NEW.campaign;
    END IF;
END //
DELIMITER ; 