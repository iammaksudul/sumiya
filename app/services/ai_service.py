from typing import Dict, Any, Optional
import torch
from transformers import AutoModelForCausalLM, AutoTokenizer, pipeline
import re
import json
from app.core.config import settings

class AIService:
    def __init__(self):
        self.model = None
        self.tokenizer = None
        self.conversation_history = []
        self.context = {}
        self._initialize_model()

    def _initialize_model(self):
        """Initialize the model and tokenizer with enhanced capabilities"""
        if self.model is None or self.tokenizer is None:
            model_name = settings.AI_MODEL_NAME
            self.tokenizer = AutoTokenizer.from_pretrained(model_name)
            self.model = AutoModelForCausalLM.from_pretrained(
                model_name,
                torch_dtype=torch.float16,
                device_map="auto"
            )
            # Enable model features for better conversation
            self.model.config.pad_token_id = self.tokenizer.eos_token_id
            self.model.config.use_cache = True

    def _preprocess_input(self, text: str) -> str:
        """Clean and normalize input text"""
        # Remove extra whitespace
        text = re.sub(r'\s+', ' ', text).strip()
        # Fix common typos
        text = self._fix_typos(text)
        return text

    def _fix_typos(self, text: str) -> str:
        """Fix common typos and misspellings"""
        common_typos = {
            'linux': 'Linux',
            'ubuntu': 'Ubuntu',
            'centos': 'CentOS',
            'debian': 'Debian',
            'nginx': 'Nginx',
            'apache': 'Apache',
            'mysql': 'MySQL',
            'postgresql': 'PostgreSQL',
            'docker': 'Docker',
            'kubernetes': 'Kubernetes',
            'k8s': 'Kubernetes',
            'aws': 'AWS',
            'azure': 'Azure',
            'gcp': 'GCP',
            'devops': 'DevOps',
            'ci/cd': 'CI/CD',
            'cicd': 'CI/CD',
        }
        for typo, correction in common_typos.items():
            text = re.sub(rf'\b{typo}\b', correction, text, flags=re.IGNORECASE)
        return text

    def _get_completion(self, prompt: str, max_length: int = 1000) -> str:
        """Generate a response with context awareness"""
        # Add conversation history to context
        context = "\n".join([f"User: {msg['user']}\nAssistant: {msg['assistant']}" 
                           for msg in self.conversation_history[-5:]])  # Keep last 5 exchanges
        
        full_prompt = f"""Previous conversation:
{context}

Current user query: {prompt}

Please provide a helpful, conversational response that:
1. Addresses the user's needs directly
2. Uses natural, friendly language
3. Provides clear explanations
4. Suggests relevant follow-up actions
5. Maintains context from previous exchanges

Response:"""

        inputs = self.tokenizer(full_prompt, return_tensors="pt").to(self.model.device)
        outputs = self.model.generate(
            **inputs,
            max_length=max_length,
            num_return_sequences=1,
            temperature=0.7,
            top_p=0.9,
            do_sample=True,
            pad_token_id=self.tokenizer.eos_token_id
        )
        response = self.tokenizer.decode(outputs[0], skip_special_tokens=True)
        
        # Extract just the response part
        response = response.split("Response:")[-1].strip()
        
        # Update conversation history
        self.conversation_history.append({
            "user": prompt,
            "assistant": response
        })
        
        return response

    def _understand_intent(self, text: str) -> Dict[str, Any]:
        """Analyze user input to understand intent and context"""
        text = text.lower()
        intent = {
            "type": "general",
            "confidence": 0.0,
            "entities": [],
            "context": {}
        }
        
        # Detect command generation intent
        if any(word in text for word in ["command", "run", "execute", "how to", "show me"]):
            intent["type"] = "command_generation"
            intent["confidence"] = 0.8
        
        # Detect script creation intent
        elif any(word in text for word in ["script", "create", "write", "make", "generate"]):
            intent["type"] = "script_creation"
            intent["confidence"] = 0.8
        
        # Detect configuration analysis intent
        elif any(word in text for word in ["config", "analyze", "check", "verify", "test"]):
            intent["type"] = "config_analysis"
            intent["confidence"] = 0.8
        
        # Detect cPanel solution intent
        elif any(word in text for word in ["cpanel", "whm", "hosting", "website", "domain"]):
            intent["type"] = "cpanel_solution"
            intent["confidence"] = 0.8
        
        # Extract entities (e.g., service names, commands, parameters)
        entities = re.findall(r'\b(nginx|apache|mysql|postgresql|docker|kubernetes|aws|azure|gcp)\b', text)
        intent["entities"] = list(set(entities))
        
        return intent

    async def generate_response(self, user_input: str) -> str:
        """Generate a human-like response to user input"""
        # Preprocess input
        cleaned_input = self._preprocess_input(user_input)
        
        # Understand user intent
        intent = self._understand_intent(cleaned_input)
        
        # Generate appropriate response based on intent
        if intent["type"] == "command_generation":
            response = await self.generate_linux_command(cleaned_input)
        elif intent["type"] == "script_creation":
            response = await self.generate_script(cleaned_input)
        elif intent["type"] == "config_analysis":
            response = await self.analyze_config(cleaned_input)
        elif intent["type"] == "cpanel_solution":
            response = await self.generate_cpanel_solution(cleaned_input)
        else:
            response = self._get_completion(cleaned_input)
        
        # Add follow-up suggestions based on context
        if intent["confidence"] > 0.7:
            response += "\n\nWould you like me to explain any part of this in more detail?"
        
        return response

    async def generate_linux_command(self, requirements: str) -> str:
        """Generate Linux commands with natural language understanding"""
        prompt = f"""Based on the following requirements, generate a Linux command or series of commands.
Consider the user's intent and provide a clear explanation.

Requirements: {requirements}

Please provide:
1. The command(s) with explanations
2. Any necessary prerequisites
3. Safety considerations
4. Expected output

Command:"""
        
        response = self._get_completion(prompt)
        return response

    async def generate_script(self, requirements: str) -> str:
        """Generate scripts with natural language understanding"""
        prompt = f"""Create a script based on the following requirements.
Make it robust, well-documented, and user-friendly.

Requirements: {requirements}

Please provide:
1. The complete script with comments
2. Usage instructions
3. Error handling
4. Example usage

Script:"""
        
        response = self._get_completion(prompt)
        return response

    async def analyze_config(self, config_text: str) -> str:
        """Analyze configuration files with natural language understanding"""
        prompt = f"""Analyze the following configuration and provide insights.
Focus on security, performance, and best practices.

Configuration:
{config_text}

Please provide:
1. Configuration analysis
2. Potential issues
3. Improvement suggestions
4. Security considerations

Analysis:"""
        
        response = self._get_completion(prompt)
        return response

    async def generate_cpanel_solution(self, issue_description: str) -> str:
        """Generate cPanel solutions with natural language understanding"""
        prompt = f"""Provide a solution for the following cPanel/WHM issue.
Include step-by-step instructions and best practices.

Issue: {issue_description}

Please provide:
1. Problem analysis
2. Step-by-step solution
3. Prevention tips
4. Additional resources

Solution:"""
        
        response = self._get_completion(prompt)
        return response 