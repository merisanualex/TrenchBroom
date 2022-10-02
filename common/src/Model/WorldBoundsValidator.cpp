/*
 Copyright (C) 2010-2017 Kristian Duske

 This file is part of TrenchBroom.

 TrenchBroom is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 TrenchBroom is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with TrenchBroom. If not, see <http://www.gnu.org/licenses/>.
 */

#include "WorldBoundsValidator.h"

#include "Model/BrushNode.h"
#include "Model/EntityNode.h"
#include "Model/Issue.h"
#include "Model/IssueQuickFix.h"
#include "Model/MapFacade.h"

#include <string>

namespace TrenchBroom {
namespace Model {
class WorldBoundsValidator::WorldBoundsIssue : public Issue {
public:
  friend class WorldBoundsIssueQuickFix;

public:
  static const IssueType Type;

public:
  explicit WorldBoundsIssue(Node& node)
    : Issue(node) {}

  IssueType doGetType() const override { return Type; }

  std::string doGetDescription() const override { return "Object is out of world bounds"; }
};

class WorldBoundsValidator::WorldBoundsIssueQuickFix : public IssueQuickFix {
public:
  WorldBoundsIssueQuickFix()
    : IssueQuickFix(WorldBoundsIssue::Type, "Delete objects") {}

private:
  void doApply(MapFacade* facade, const IssueList& /* issues */) const override {
    facade->deleteObjects();
  }
};

const IssueType WorldBoundsValidator::WorldBoundsIssue::Type = Issue::freeType();

WorldBoundsValidator::WorldBoundsValidator(const vm::bbox3& bounds)
  : Validator(WorldBoundsIssue::Type, "Objects out of world bounds")
  , m_bounds(bounds) {
  addQuickFix(std::make_unique<WorldBoundsIssueQuickFix>());
}

void WorldBoundsValidator::doValidate(EntityNode& entity, IssueList& issues) const {
  if (!m_bounds.contains(entity.logicalBounds()))
    issues.push_back(new WorldBoundsIssue(entity));
}

void WorldBoundsValidator::doValidate(BrushNode& brush, IssueList& issues) const {
  if (!m_bounds.contains(brush.logicalBounds()))
    issues.push_back(new WorldBoundsIssue(brush));
}
} // namespace Model
} // namespace TrenchBroom
