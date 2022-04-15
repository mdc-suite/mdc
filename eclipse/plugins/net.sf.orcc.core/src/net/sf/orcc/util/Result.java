/*
 * Copyright (c) 2014, IETR/INSA of Rennes
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * 
 *   * Redistributions of source code must retain the above copyright notice,
 *     this list of conditions and the following disclaimer.
 *   * Redistributions in binary form must reproduce the above copyright notice,
 *     this list of conditions and the following disclaimer in the documentation
 *     and/or other materials provided with the distribution.
 *   * Neither the name of the IETR/INSA of Rennes nor the names of its
 *     contributors may be used to endorse or promote products derived from this
 *     software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
 * WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */
package net.sf.orcc.util;

/**
 * Used to store files writing results. It maintains the number of really
 * written files in an operation, and the number of cached files (not written
 * because already up-to-date)
 * 
 * @author Antoine Lorence
 * 
 */
public class Result {

	private int written = 0;
	private int cached = 0;

	private Result(int written, int cached) {
		this.written = written;
		this.cached = cached;
	}

	/**
	 * Create a new empty Result instance.
	 * 
	 * @return
	 */
	public static Result newInstance() {
		return new Result(0, 0);
	}

	/**
	 * Create a new Result instance for a written file.
	 * 
	 * @return
	 */
	public static Result newOkInstance() {
		return new Result(1, 0);
	}

	/**
	 * Create a new Result instance for a cached file.
	 * 
	 * @return
	 */
	public static Result newCachedInstance() {
		return new Result(0, 1);
	}

	/**
	 * Merge the given <em>other</em> instance into this one by adding their
	 * respective members.
	 * 
	 * @param other
	 * @return
	 */
	public Result merge(final Result other) {
		written += other.written;
		cached += other.cached;
		return this;
	}

	public int cached() {
		return cached;
	}

	public int written() {
		return written;
	}

	@Override
	public boolean equals(Object obj) {
		if(obj instanceof Result) {
			return ((Result) obj).written == written
					&& ((Result) obj).cached == cached;
		}
		return false;
	}

	@Override
	public String toString() {
		final StringBuilder builder = new StringBuilder();
		builder.append("Result: ");
		builder.append(written).append (" file(s) written - ");
		builder.append(cached).append(" file(s) cached");
		return builder.toString();
	}

	public boolean isEmpty() {
		return written == 0 && cached == 0;
	}
}
