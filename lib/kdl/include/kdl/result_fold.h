/*
 Copyright 2020 Kristian Duske

 Permission is hereby granted, free of charge, to any person obtaining a copy of this
 software and associated documentation files (the "Software"), to deal in the Software
 without restriction, including without limitation the rights to use, copy, modify, merge,
 publish, distribute, sublicense, and/or sell copies of the Software, and to permit
 persons to whom the Software is furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all copies or
 substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
 INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
 PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
 FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
 OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 DEALINGS IN THE SOFTWARE.
*/

#pragma once

#include "kdl/meta_utils.h"
#include "kdl/overload.h"
#include "kdl/result.h"

#include <iterator>
#include <vector>

namespace kdl
{
/**
 * Folds the given range of results into a single result with a vector of success values
 * or an error. If given void results, the result is a void result again. The returned
 * result has the same error types as the results in the given range.
 *
 * If any of the given results contains an error, that error is returned.
 */
template <typename I>
auto fold_results(I cur, I end)
{
  using in_result_type = typename std::iterator_traits<I>::value_type;
  using in_value_type = typename in_result_type::value_type;

  if constexpr (std::is_same_v<in_value_type, void>)
  {
    using out_result_type = typename in_result_type::template with_value_type<void>;

    while (cur != end)
    {
      if (cur->is_error())
      {
        return *cur;
      }
      ++cur;
    }

    return out_result_type{};
  }
  else
  {
    using vector_type = std::vector<in_value_type>;
    using out_result_type =
      typename in_result_type::template with_value_type<vector_type>;
    using i_category = typename std::iterator_traits<I>::iterator_category;

    auto result_vector = vector_type{};
    if constexpr (std::is_same_v<i_category, std::random_access_iterator_tag>)
    {
      result_vector.reserve(static_cast<std::size_t>(end - cur));
    }

    while (cur != end)
    {
      if constexpr (in_result_type::error_count > 0)
      {
        if (cur->is_error())
        {
          return std::visit(
            [](auto&& e) { return out_result_type{std::forward<decltype(e)>(e)}; },
            std::move(*cur).error());
        }
      }

      result_vector.push_back(std::move(*cur).value());
      ++cur;
    }

    return out_result_type{std::move(result_vector)};
  }
}

template <typename C>
auto fold_results(C&& c)
{
  return fold_results(std::begin(c), std::end(c));
}

} // namespace kdl
