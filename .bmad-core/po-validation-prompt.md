# PO Agent User Story Validation Prompt Template

## Overview
This prompt template is designed for Product Owner agents to systematically validate user stories against comprehensive quality standards and business requirements. Each agent will be assigned a specific story file to validate using the `*validate-story-draft {story}` command.

## Context & Background

### Platform Context
- **Comprehensive e-commerce and content platform** with integrated social commerce features
- **Multi-sided marketplace** serving merchants, content creators, and consumers
- **Mobile-first approach** with Flutter cross-platform development
- **Integrated video commerce** with shoppable content capabilities

### Target Users
1. **Merchants**: Small to medium businesses selling physical/digital products
2. **Content Creators**: Influencers, video producers, and storytellers
3. **Consumers**: End users discovering and purchasing products through content

### Technical Stack
- **Frontend**: Flutter (cross-platform mobile apps)
- **Backend**: RESTful APIs with GraphQL support
- **Architecture**: Clean Architecture with domain-driven design
- **Security**: Multi-factor authentication, PCI compliance, data encryption
- **Performance**: Optimized for mobile networks and offline capabilities

### Core Platform Features
- User authentication and profile management
- Product catalog and inventory management
- Video capture, editing, and publishing
- Shopping cart and checkout flows
- Payment processing (cards, digital wallets, BNPL)
- Content discovery and personalization
- Analytics and admin dashboard

---

## Validation Criteria

### 1. Business Value Clarity
- **Problem Statement**: Clear identification of the user problem being solved
- **Value Proposition**: Explicit articulation of business value and user benefit
- **Market Impact**: Understanding of how this feature drives platform growth
- **ROI Justification**: Clear return on investment rationale
- **Competitive Advantage**: Differentiation from existing solutions

### 2. User Acceptance Criteria Completeness
- **Given-When-Then Format**: Properly structured acceptance criteria
- **Edge Cases**: Coverage of error states and exceptional scenarios
- **User Flow**: Complete end-to-end user journey mapping
- **Success Metrics**: Defined, measurable success criteria
- **Validation Methods**: How acceptance will be verified

### 3. Technical Feasibility Assessment
- **Architecture Alignment**: Consistency with existing system architecture
- **Technology Stack Compatibility**: Appropriateness for current tech stack
- **Complexity Analysis**: Realistic assessment of implementation complexity
- **Performance Considerations**: Impact on system performance and scalability
- **Integration Points**: Identification of required integrations

### 4. Dependencies Identification
- **Upstream Dependencies**: Features/stories that must be completed first
- **Downstream Dependencies**: Features that depend on this story
- **External Dependencies**: Third-party services, APIs, or integrations
- **Resource Dependencies**: Specific team members or expertise required
- **Timeline Dependencies**: Critical path considerations

### 5. Risk Assessment
- **Technical Risks**: Implementation challenges and potential blockers
- **Business Risks**: Market timing, competitive, or adoption risks
- **Security Risks**: Authentication, authorization, data privacy concerns
- **Performance Risks**: Scalability, latency, or reliability issues
- **Compliance Risks**: Regulatory or legal compliance considerations

### 6. Readiness for Development
- **Specification Completeness**: All necessary details provided
- **Design Assets**: UI/UX specifications and design system alignment
- **API Definitions**: Clear API contracts and data models
- **Test Strategy**: Approach to testing and validation
- **Deployment Plan**: Rollout strategy and monitoring

### 7. Alignment with Product Roadmap
- **Strategic Fit**: Alignment with overall product vision and strategy
- **Priority Consistency**: Matches prioritized product roadmap
- **Feature Dependencies**: Proper sequencing in development timeline
- **Resource Allocation**: Consistency with available team capacity
- **Milestone Alignment**: Supports upcoming product milestones

---

## Quality Standards

### INVEST Principles Assessment

#### Independent
- Story can be developed and tested independently
- Minimal dependencies on other stories
- Self-contained functionality
- Clear boundaries and scope

#### Negotiable
- Details can be discussed and refined
- Implementation approach is flexible
- Acceptance criteria can be adjusted
- Priority can be negotiated based on value

#### Valuable
- Clear user or business value
- Addresses specific user needs
- Contributes to platform goals
- Justifies development effort

#### Estimable
- Scope is well-defined and bounded
- Technical approach is understood
- Effort can be reasonably estimated
- Complexity is appropriately assessed

#### Small
- Can be completed in a single sprint
- Focused on a single capability
- Manageable scope for delivery
- Clear definition of done

#### Testable
- Acceptance criteria are verifiable
- Success metrics are measurable
- Test scenarios are definable
- Validation approach is clear

### User Journey Mapping
- **User Personas**: Clear identification of target user types
- **User Goals**: Specific objectives the story enables
- **Touchpoints**: All interaction points with the platform
- **Emotional Journey**: User experience and satisfaction factors
- **Accessibility**: Consideration of diverse user needs

### Measurable Success Criteria
- **Quantitative Metrics**: Specific numbers, percentages, or thresholds
- **Qualitative Metrics**: User satisfaction, experience improvements
- **Business KPIs**: Impact on revenue, engagement, or retention
- **Technical Metrics**: Performance, reliability, or scalability targets
- **Timeline Metrics**: Delivery milestones and time-to-value

### Proper Prioritization
- **Business Value**: High-impact features prioritized
- **User Impact**: Critical user needs addressed first
- **Technical Dependencies**: Sequenced based on dependencies
- **Resource Availability**: Matches team capacity and expertise
- **Market Timing**: Aligns with market opportunities

### Resource Requirements
- **Development Effort**: Realistic time and effort estimates
- **Team Composition**: Required skills and team members
- **Design Resources**: UI/UX design and review requirements
- **QA Resources**: Testing strategy and resource needs
- **Infrastructure Requirements**: Server, database, or API needs

---

## Output Format

### Story Header
```markdown
## Story Validation: [Story ID] - [Story Title]

**Category**: [Feature Area]
**Priority**: [High/Medium/Low]
**Estimated Effort**: [Story Points or Days]
**Target Sprint**: [Sprint Number]
**Validated By**: [PO Agent ID]
**Validation Date**: [Date]
```

### Validation Scorecard

#### Overall Assessment
- **Validation Score**: [1-10]
- **Readiness Status**: [Ready/Needs Work/Blocked]
- **Confidence Level**: [High/Medium/Low]

#### Detailed Scoring
```
Business Value Clarity:          [Score 1-10]
Acceptance Criteria Completeness: [Score 1-10]
Technical Feasibility:          [Score 1-10]
Dependencies Identification:    [Score 1-10]
Risk Assessment:                [Score 1-10]
Development Readiness:          [Score 1-10]
Roadmap Alignment:              [Score 1-10]
```

### Strengths Identified
List 3-5 key strengths of the story:

1. **[Strength Category]**: [Specific strength with details]
2. **[Strength Category]**: [Specific strength with details]
3. **[Strength Category]**: [Specific strength with details]
4. **[Strength Category]**: [Specific strength with details]
5. **[Strength Category]**: [Specific strength with details]

### Gaps and Weaknesses Found
List 3-5 critical gaps or weaknesses:

1. **[Gap Category]**: [Specific gap with impact assessment]
2. **[Gap Category]**: [Specific gap with impact assessment]
3. **[Gap Category]**: [Specific gap with impact assessment]
4. **[Gap Category]**: [Specific gap with impact assessment]
5. **[Gap Category]**: [Specific gap with impact assessment]

### Recommended Improvements
Provide specific, actionable recommendations:

#### Immediate Actions (Required before development)
1. **[Action Item]**: [Specific action with owner and timeline]
2. **[Action Item]**: [Specific action with owner and timeline]

#### Enhancements (Recommended for next iteration)
1. **[Enhancement]**: [Specific enhancement suggestion]
2. **[Enhancement]**: [Specific enhancement suggestion]

#### Long-term Considerations
1. **[Consideration]**: [Strategic consideration for future]
2. **[Consideration]**: [Strategic consideration for future]

### Readiness Assessment

#### Ready to Develop
- [x] All acceptance criteria are clear and testable
- [x] Technical approach is feasible and understood
- [x] Dependencies are identified and managed
- [x] Risks are assessed and mitigated
- [x] Resources are available and allocated
- [x] Design assets are complete and approved
- [x] Test strategy is defined and agreed upon

#### Needs Work
- [ ] Acceptance criteria require refinement
- [ ] Technical approach needs clarification
- [ ] Dependencies require resolution
- [ ] Risk mitigation strategies needed
- [ ] Resource allocation requires adjustment
- [ ] Design assets need completion
- [ ] Test strategy requires development

#### Blocked
- [ ] Critical dependencies are unresolved
- [ ] Technical feasibility is questionable
- [ ] Resource constraints exist
- [ ] Business value is unclear
- [ ] Roadmap priority conflicts exist
- [ ] Major risks are unmitigated
- [ ] Compliance concerns are unresolved

### Priority and Recommendations

#### Priority Level
- **Current Priority**: [High/Medium/Low]
- **Recommended Priority**: [High/Medium/Low]
- **Priority Justification**: [Brief rationale]

#### Next Steps
1. **[Step 1]**: [Immediate next action with owner]
2. **[Step 2]**: [Follow-up action with owner]
3. **[Step 3]**: [Subsequent action with owner]

#### Stakeholder Communication
- **Required Approvals**: [List of required approvals]
- **Communication Plan**: [How to communicate results]
- **Escalation Path**: [Process for addressing issues]

---

## Special Considerations by Feature Area

### Authentication & Security Stories
- **Multi-factor authentication**: Security vs. user experience balance
- **Biometric authentication**: Device compatibility and fallback mechanisms
- **Session management**: Security and performance implications
- **Account recovery**: Security and user experience trade-offs
- **Compliance**: GDPR, CCPA, PCI-DSS requirements

### E-commerce Features
- **Payment processing**: Security, compliance, and user experience
- **Inventory management**: Real-time synchronization and accuracy
- **Cart management**: Persistence, synchronization, and abandonment
- **Shipping and fulfillment**: Carrier integration and tracking
- **Tax and pricing**: Regional compliance and accuracy

### Content Creation & Publishing
- **Video processing**: Performance, quality, and storage considerations
- **Timeline editing**: Real-time performance and user experience
- **Media management**: Storage optimization and retrieval
- **Publishing workflow**: Approval processes and scheduling
- **Content moderation**: Automated and manual review processes

### Mobile Experience
- **Device integration**: Camera, location, sensors, and permissions
- **Offline functionality**: Data synchronization and conflict resolution
- **Performance optimization**: Memory, battery, and network efficiency
- **Push notifications**: User experience and battery impact
- **App store compliance**: Store guidelines and review processes

### Platform Infrastructure
- **API design**: RESTful principles and GraphQL optimization
- **Database architecture**: Scalability and performance considerations
- **Event streaming**: Real-time processing and reliability
- **Monitoring and analytics**: Performance tracking and alerting
- **Developer experience**: Documentation and SDK usability

---

## Validation Process Guidelines

### Pre-Validation Preparation
1. **Review Existing Stories**: Understand related stories and epics
2. **Check Product Roadmap**: Verify alignment with strategic priorities
3. **Assess Team Capacity**: Consider current workload and expertise
4. **Review Dependencies**: Identify upstream and downstream dependencies
5. **Check Compliance Requirements**: Ensure regulatory compliance

### During Validation
1. **Systematic Review**: Follow the validation criteria in order
2. **Critical Thinking**: Question assumptions and identify gaps
3. **User-Centric Focus**: Ensure user needs are properly addressed
4. **Technical Pragmatism**: Balance ambition with feasibility
5. **Business Alignment**: Verify strategic alignment and value

### Post-Validation Actions
1. **Document Findings**: Complete the validation output format
2. **Identify Blockers**: Flag any showstopper issues immediately
3. **Recommend Next Steps**: Provide clear action items
4. **Communicate Results**: Share findings with stakeholders
5. **Track Improvements**: Monitor story improvements over time

### Quality Assurance
1. **Consistency Check**: Ensure validation approach is consistent
2. **Bias Awareness**: Guard against personal biases
3. **Continuous Improvement**: Learn from validation outcomes
4. **Feedback Loop**: Incorporate feedback from development teams
5. **Metrics Tracking**: Monitor validation effectiveness

---

## Example Validation Output

## Story Validation: US-001 - User Registration with Email Verification

**Category**: Authentication
**Priority**: High
**Estimated Effort**: 5 story points
**Target Sprint**: Sprint 12
**Validated By**: PO Agent 01
**Validation Date**: 2025-09-22

### Overall Assessment
- **Validation Score**: 8/10
- **Readiness Status**: Ready
- **Confidence Level**: High

### Detailed Scoring
```
Business Value Clarity:          9/10
Acceptance Criteria Completeness: 8/10
Technical Feasibility:          9/10
Dependencies Identification:    7/10
Risk Assessment:                8/10
Development Readiness:          9/10
Roadmap Alignment:              9/10
```

### Strengths Identified
1. **User Journey**: Well-defined registration flow with clear user steps
2. **Security Considerations**: Comprehensive security measures included
3. **Error Handling**: Detailed edge case coverage for registration failures
4. **Integration Points**: Clear API integration requirements
5. **Compliance**: GDPR and email compliance requirements addressed

### Gaps and Weaknesses Found
1. **Performance**: No performance metrics for registration response time
2. **A/B Testing**: Lacks plan for testing different registration flows
3. **Analytics**: Insufficient tracking requirements for user drop-off points
4. **Localization**: Missing requirements for multi-language support
5. **Mobile Optimization**: Limited consideration for mobile-specific UX

### Recommended Improvements

#### Immediate Actions (Required before development)
1. **Performance Requirements**: Add response time targets (< 2 seconds)
2. **Analytics Integration**: Define key metrics and tracking points

#### Enhancements (Recommended for next iteration)
1. **A/B Testing Framework**: Implement capability for flow optimization
2. **Progressive Profiling**: Consider step-by-step profile completion

#### Long-term Considerations
1. **Social Authentication**: Plan for social login integration
2. **Advanced Verification**: Consider SMS verification fallback

### Readiness Assessment

#### Ready to Develop
- [x] All acceptance criteria are clear and testable
- [x] Technical approach is feasible and understood
- [x] Dependencies are identified and managed
- [x] Risks are assessed and mitigated
- [x] Resources are available and allocated
- [x] Design assets are complete and approved
- [x] Test strategy is defined and agreed upon

### Priority and Recommendations

#### Priority Level
- **Current Priority**: High
- **Recommended Priority**: High
- **Priority Justification**: Critical user onboarding functionality with high business impact

#### Next Steps
1. **Add Performance Requirements**: Product Owner to add SLA requirements
2. **Define Analytics Points**: Data analyst to define tracking implementation
3. **Development Kickoff**: Tech lead to schedule sprint planning

#### Stakeholder Communication
- **Required Approvals**: Product Manager, Tech Lead, UX Designer
- **Communication Plan**: Present at sprint planning ceremony
- **Escalation Path**: Escalate to Head of Product for priority conflicts

---

## Usage Instructions

### For PO Agents
1. **Load this template** as a dependency file when executing validation tasks
2. **Apply the framework** systematically to each assigned story
3. **Use the output format** to structure validation results
4. **Be thorough but practical** in assessment and recommendations
5. **Focus on readiness** for development and delivery success

### For Parallel Validation
1. **Distribute stories** evenly among available PO agents
2. **Standardize approach** using this template for consistency
3. **Coordinate dependencies** between related stories
4. **Consolidate results** for comprehensive quality assessment
5. **Track validation metrics** to improve process effectiveness

### Continuous Improvement
1. **Gather feedback** from development teams on validation quality
2. **Update criteria** based on lessons learned and new requirements
3. **Refine scoring** to improve accuracy and consistency
4. **Share best practices** among PO agents
5. **Monitor impact** on development success and product quality

---

## Template Version
**Version**: 1.0
**Last Updated**: 2025-09-22
**Maintained By**: Product Owner Team
**Review Frequency**: Quarterly or as needed

This template provides a comprehensive framework for validating user stories across all feature areas of the platform. It ensures consistent quality assessment and readiness for development while maintaining alignment with product strategy and business goals.